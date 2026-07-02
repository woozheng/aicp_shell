# HarmonyOS 编译配置文档
## 1. 生成鸿蒙工程目录
执行命令：
flutter create --platforms ohos .

## 2. module.json5 完整权限配置
路径：ohos/entry/src/main/module.json5
{
  "module": {
    "name": "entry",
    "type": "har",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:pages",
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:mic_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA_IMAGE",
        "reason": "$string:gallery_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.WRITE_MEDIA",
        "reason": "$string:media_write_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:location_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.BLUETOOTH",
        "reason": "$string:bt_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.BLUETOOTH_ADMIN",
        "reason": "$string:bt_admin_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.NOTIFICATION_AGENT",
        "reason": "$string:notify_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.VIBRATE",
        "reason": "$string:vibrate_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.CALL_PHONE",
        "reason": "$string:call_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.SEND_SMS",
        "reason": "$string:sms_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}

## 3. 字符串资源 string.json
路径：ohos/entry/src/main/resources/base/element/string.json
[
  {
    "name": "camera_reason",
    "value": "用于拍照、扫码识别功能"
  },
  {
    "name": "mic_reason",
    "value": "用于录制音频"
  },
  {
    "name": "gallery_reason",
    "value": "读取相册图片用于上传、预览"
  },
  {
    "name": "media_write_reason",
    "value": "保存拍摄/下载图片到本地"
  },
  {
    "name": "location_reason",
    "value": "获取定位、扫描周边蓝牙设备"
  },
  {
    "name": "bt_reason",
    "value": "扫描、连接蓝牙外设"
  },
  {
    "name": "bt_admin_reason",
    "value": "管理蓝牙设备连接状态"
  },
  {
    "name": "notify_reason",
    "value": "展示本地消息通知"
  },
  {
    "name": "vibrate_reason",
    "value": "操作震动反馈"
  },
  {
    "name": "call_reason",
    "value": "拨打电话"
  },
  {
    "name": "sms_reason",
    "value": "发送短信"
  }
]

## 4. 编译前置修改
1. pubspec.yaml 取消 camera_ohos 依赖注释
2. 执行 flutter pub get
3. flutter run -d ohos