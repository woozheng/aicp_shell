// lib/core/agent.dart
// 对应 Python core.py 的 class Agent

class ShellAgent {
  Map<String, dynamic> _props = {};

  ShellAgent([Map<String, dynamic>? props]) {
    if (props != null) {
      _props = props;
    }
  }

  // 对应 Python 的 __init__(self, **kwargs)
  // 用法: agent.set('llm', llmInstance)
  void set(String key, dynamic value) {
    _props[key] = value;
  }

  // 对应 Python 的 get(self, key, default=None)
  dynamic get(String key, [dynamic defaultValue]) {
    return _props.containsKey(key) ? _props[key] : defaultValue;
  }

  // 动态属性访问（类似 Python 的 self.xxx）
  // 用法: agent['llm'] 或 agent['llm'] = xxx
  dynamic operator [](String key) => _props[key];
  void operator []=(String key, dynamic value) => _props[key] = value;

  // 检查是否存在某个属性
  bool has(String key) => _props.containsKey(key);

  // 获取所有属性名
  List<String> keys() => _props.keys.toList();

  // 转为 Map
  Map<String, dynamic> toMap() => Map.from(_props);

  @override
  String toString() => 'ShellAgent(${_props.keys.join(", ")})';
}