import 'package:reflectable/reflectable.dart';

class _EnableReflection extends Reflectable{
  const _EnableReflection(): super(invokingCapability);
}

const EnableReflection = _EnableReflection();
