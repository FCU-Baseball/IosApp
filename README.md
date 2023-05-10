# IosApp  主程式 ViewController.swift
##@IBAction func recordButton(_ sender: Any)           按錄影鍵後錄影開始
##self.videoPicker.gzipstream(file: self.tmpOutputURL) 影片POST到Server
##@IBAction func replayVideo(_ sender: UIButton)       回放慢動作影片與結果

## ViewController.swift
override func viewDidLoad() 程式進入點

### 相機初始化
#### settingPreviewLayer()
功能 : 設定預覽錄影畫面

#### settingFPS()
功能 : 設定 像素1080p 與 該相機最高幀數

#### cameraSetting()
功能 : 設定對焦方式為自動對焦一次

#### @IBAction func ServerInput(_ sender: Any)
功能 : 手動輸入Server IP

### 模式切換
#### @IBAction func predModeClicked(_ sender: UISegmentedControl) 
功能 : 選擇球速或轉速功能 

#### @IBAction func screenModeClicked(_ sender: UISegmentedControl) 
功能 : 切換 關/對焦鎖定/pixeltometer校正

### 錄影流程
#### @IBAction func recordButton(_ sender: Any)  
功能 : 按錄影鍵後錄影開始
#### self.videoPicker.gzipstream(file: self.tmpOutputURL)
功能 : 影片POST到Server
#### func fileOutput(...)
功能 : 錄影完成後自動呼叫，之後儲存影片到相簿
#### @IBAction func replayVideo(_ sender: UIButton)
功能 : 回放慢動作影片與結果

### 焦距設定
#### override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
功能 : 點擊螢幕獲取對焦框位置
#### func focalSetting(touchX:CGFloat, touchY:CGFloat)
功能 : 設定對焦框位置
  
### 球速額外使用函式
#### override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
功能 :　計算校正參數
#### @IBAction func sendParameter(_ sender: UIButton) 
功能 : 傳送校正參數到Server
  
## VideoPicker.swift

### jsonPost_parameter
功能 :　Post校正參數到Server
### gzipstream
功能 : Post影片到Server  
