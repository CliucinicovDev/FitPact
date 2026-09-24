import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';
import 'package:fitpact/core/anti_cheat/layer_1_on_device.dart';
import 'package:fitpact/core/anti_cheat/layer_2_on_device.dart';
import 'package:fitpact/core/anti_cheat/layer_3_server.dart';
import 'package:fitpact/core/anti_cheat/layer_4_community.dart';
import 'package:fitpact/core/proof/proof_generator.dart';

ProofFrame frame(int repIndex, DateTime ts, String deviceId,
 {double y = 0.5, double x = 0.5}) =>
 ProofFrame(
 repIndex: repIndex,
 timestamp: ts,
 deviceId: deviceId,
 landmarks: {
 'nose': [x, y],
 },
 );

void main() {
 final base = DateTime(2026, 9, 19, 10);

 List<ProofFrame> cleanFrames() => [
 frame(0, base, 'd1', y: 0.5),
  frame(0, base.add(const Duration(milliseconds: 150)), 'd1', y: 0.4),
  frame(0, base.add(const Duration(milliseconds: 300)), 'd1', y: 0.3),
  frame(0, base.add(const Duration(milliseconds: 450)), 'd1', y: 0.2),
  frame(0, base.add(const Duration(milliseconds: 600)), 'd1', y: 0.1),
  ];

 group('ProofGenerator', () {
 final gen = ProofGenerator(key: 'secret');

 test('generates a signed proof for 3-5 frames', () {
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 expect(proof['sessionId'], 's1');
 expect(proof['repIndex'], 0);
 expect((proof['frames'] as List).length, 5);
 expect(proof['hmacSignature'], isNotEmpty);
 expect(gen.verify(proof), isTrue);
 });

 test('rejects fewer than 3 or more than 5 frames', () {
 expect(
 () => gen.generate(sessionId: 's1', repIndex: 0, frames: []),
 throwsArgumentError);
 expect(
 () => gen.generate(
 sessionId: 's1',
 repIndex: 0,
 frames: List.generate(6, (i) => frame(0, base, 'd1'))),
 throwsArgumentError);
 });

 test('detects tampering with the payload', () {
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 (proof['frames'] as List).first['landmarks']['nose'] = [0.9, 0.9];
 expect(gen.verify(proof), isFalse);
 });

 test('deriveKey is stable per user', () {
 expect(ProofGenerator.deriveKey('u1', 'salt'),
 ProofGenerator.deriveKey('u1', 'salt'));
 expect(ProofGenerator.deriveKey('u1', 'salt'),
 isNot(ProofGenerator.deriveKey('u2', 'salt')));
 });
 });

 group('Layer1OnDevice', () {
 const layer = Layer1OnDevice();

 test('accepts clean frames', () {
 expect(layer.check(cleanFrames()), CheatVerdict.clean);
 });

 test('flags non-monotonic timestamps', () {
 final frames = [
 frame(0, base, 'd1'),
 frame(0, base, 'd1'), // dt == 0
 frame(0, base.add(const Duration(milliseconds: 100)), 'd1'),
 ];
 expect(layer.check(frames), CheatVerdict.suspect);
 });

 test('flags frozen frames (identical landmarks)', () {
 final frames = [
 frame(0, base, 'd1'),
 frame(0, base.add(const Duration(milliseconds: 100)), 'd1'),
 frame(0, base.add(const Duration(milliseconds: 200)), 'd1'),
 ];
 expect(layer.check(frames), CheatVerdict.suspect);
 });

 test('flags implausibly large jumps', () {
 final frames = [
 frame(0, base, 'd1', x: 0.1),
 frame(0, base.add(const Duration(milliseconds: 100)), 'd1', x: 0.9),
 frame(0, base.add(const Duration(milliseconds: 200)), 'd1', x: 0.2),
 ];
 expect(layer.check(frames), CheatVerdict.suspect);
 });
 });

 group('Layer2OnDevice', () {
 const layer = Layer2OnDevice();

 test('accepts a plausible rep', () {
 expect(
 layer.check(cleanFrames(),
 angleOf: (f) => 170 - (f.landmarks['nose'][1] as double) * 100),
 CheatVerdict.clean);
 });

 test('flags too-short reps', () {
 final frames = [
 frame(0, base, 'd1'),
 frame(0, base.add(const Duration(milliseconds: 100)), 'd1', y: 0.4),
 ];
 expect(layer.check(frames), CheatVerdict.suspect);
 });

 test('flags insufficient angle range', () {
 expect(
 layer.check(cleanFrames(), angleOf: (f) => 90.0),
 CheatVerdict.suspect);
 });

 test('flags insufficient variance', () {
 final frames = [
 frame(0, base, 'd1', y: 0.5),
 frame(0, base.add(const Duration(milliseconds: 300)), 'd1', y: 0.5),
 frame(0, base.add(const Duration(milliseconds: 600)), 'd1', y: 0.5),
 ];
 expect(layer.check(frames), CheatVerdict.suspect);
 });
 });

 group('Layer3Server', () {
 test('accepts a valid proof', () {
 final gen = ProofGenerator(key: 'secret');
 final layer = Layer3Server(verifier: gen);
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 final result =
 layer.check(proof, expectedDeviceId: 'd1', now: base.add(const Duration(minutes: 1)));
 expect(result.verdict, CheatVerdict.clean);
 });

 test('rejects invalid HMAC', () {
 final gen = ProofGenerator(key: 'secret');
 final other = ProofGenerator(key: 'other');
 final layer = Layer3Server(verifier: other);
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 final result = layer.check(proof,
 expectedDeviceId: 'd1', now: base.add(const Duration(minutes: 1)));
 expect(result.verdict, CheatVerdict.suspect);
 expect(result.reason, contains('HMAC'));
 });

 test('rejects timestamps too far from server time', () {
 final gen = ProofGenerator(key: 'secret');
 final layer = Layer3Server(verifier: gen);
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 final result = layer.check(proof,
 expectedDeviceId: 'd1',
 now: base.add(const Duration(hours: 3)));
 expect(result.verdict, CheatVerdict.suspect);
 expect(result.reason, contains('server time'));
 });

 test('rejects deviceId mismatch', () {
 final gen = ProofGenerator(key: 'secret');
 final layer = Layer3Server(verifier: gen);
 final proof = gen.generate(
 sessionId: 's1', repIndex: 0, frames: cleanFrames());
 final result = layer.check(proof,
 expectedDeviceId: 'other-device', now: base.add(const Duration(minutes: 1)));
 expect(result.verdict, CheatVerdict.suspect);
 expect(result.reason, contains('DeviceId'));
 });
 });

 group('Layer4Community', () {
 final layer = Layer4Community();

 test('selects distinct reviewers excluding the accused', () {
 final reviewers = layer.selectReviewers(
 ['a', 'b', 'c', 'd', 'e'],
 exclude: 'a',
 );
 expect(reviewers, hasLength(3));
 expect(reviewers.toSet().length, 3);
 expect(reviewers, isNot(contains('a')));
 });

 test('reaches cheat verdict at 2/3 votes', () {
 final result = layer.resolve(
 {'r1': true, 'r2': true, 'r3': false});
 expect(result.verdict, CheatVerdict.suspect);
 });

 test('clears the rep when majority votes clean', () {
 final result = layer.resolve(
 {'r1': false, 'r2': false, 'r3': true});
 expect(result.verdict, CheatVerdict.clean);
 });

 test('inconclusive on 1/1 split', () {
 final result = layer.resolve({'r1': true, 'r2': false});
 expect(result.verdict, CheatVerdict.invalid);
 });
 });
}