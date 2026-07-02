// ============================================================
// 🔥 动态 bridge.js
// ============================================================

(function() {
  if (window.mobile) return;

  console.log('📱 注入 mobile 动态桥...');

  // ============================================================
  // Envelop 通信
  // ============================================================

  function _call(receiver, action, params) {
    return new Promise((resolve, reject) => {
      const id = Date.now() + '_' + Math.random().toString(36).substr(2, 6);
      window._mobileCallbacks = window._mobileCallbacks || {};
      window._mobileCallbacks[id] = { 
        resolve: function(data) { clearTimeout(timeout); resolve(data); },
        reject: function(err) { clearTimeout(timeout); reject(err); }
      };
      
      const timeout = setTimeout(() => {
        if (window._mobileCallbacks[id]) {
          delete window._mobileCallbacks[id];
          reject(new Error('超时'));
        }
      }, 30000);
      
      const envelop = {
        sender: 'web',
        receiver: receiver,
        intent: 'API_CALL',
        payload: { 
          action: action, 
          params: params || {},
          _callbackId: id 
        },
        trace_id: id,
        message_id: id,
        channel_id: 'web',
        ttl: 30,
        meta: {}
      };
      
      const message = JSON.stringify(envelop);
      
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('flutterBridge', message);
      } else {
        window.location.href = 'bridge://' + encodeURIComponent(message);
      }
    });
  }

  // ============================================================
  // 🔥 动态核心：一个 call 搞定所有
  // ============================================================

  window.mobile = {
    // 方式 1：通过 call 调用
    call: function(plugin, action, params) {
      return _call('mobile/' + plugin, action, params);
    },

    // 方式 2：通过 execute 调用（直接传 Envelop）
    execute: function(envelop) {
      return _call(envelop.receiver, envelop.payload.action, envelop.payload.params);
    },

    // 方式 3：通过代理，自动生成 window.mobile.xxx.xxx
    // 用 Proxy 实现动态调用
    get: function(target, prop) {
      // 如果属性是 call 或 execute，直接返回
      if (prop === 'call' || prop === 'execute' || prop === 'get') {
        return target[prop];
      }
      
      // 否则，返回一个动态代理
      return new Proxy({}, {
        get: function(innerTarget, method) {
          return function(params) {
            return _call('mobile/' + prop, method, params);
          };
        }
      });
    }
  };

  // 🔥 用 Proxy 包装
  window.mobile = new Proxy(window.mobile, {
    get: function(target, prop) {
      if (prop === 'call' || prop === 'execute') {
        return target[prop];
      }
      
      // 动态返回插件代理
      return new Proxy({}, {
        get: function(innerTarget, method) {
          return function(params) {
            return _call('mobile/' + prop, method, params);
          };
        }
      });
    }
  });

  console.log('✅ 动态 mobile 注入成功');
})();