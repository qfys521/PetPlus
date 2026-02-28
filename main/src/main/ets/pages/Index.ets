import { LogUtil, ToastUtil, PreferencesUtil, StrUtil } from '@pura/harmony-utils';
import { petsUserLogin } from '../api/services';
import { ApiError } from '../api/types';

@Entry
@Component
struct Index {
  @State username: string = "";
  @State password: string = "";
  @State isSelect: boolean = false;

  @State isLoggingIn: boolean = false;

  aboutToAppear() {
    const savedUsername = PreferencesUtil.getStringSync("login_username", "");
    const savedPassword = PreferencesUtil.getStringSync("login_password", "");

    if (StrUtil.isNotEmpty(savedUsername) && StrUtil.isNotEmpty(savedPassword)) {
      this.username = savedUsername;
      this.password = savedPassword;
      this.isSelect = true;

      LogUtil.info("检测到本地缓存的账号信息，正在尝试自动登录...");
      this.login();
    }
  }

  build() {
    Stack() {
      Image($r('app.media.bg1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.login_blur_layer'))
        .backdropBlur(25)

      Column() {
        Image($r('app.media.touxiang2'))
          .width(110)
          .height(110)
          .borderRadius(55)
          .margin({ top: 120, bottom: 50 })

        Column({ space: 22 }) {
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(20)
              .fontColor([Color.White])
              .margin({ right: 10 })

            TextInput({
              text: this.username,
              placeholder: "请输入用户名"
            })
              .layoutWeight(1)
              .height(45)
              .borderRadius(10)
              .backgroundColor($r('app.color.login_input_bg'))
              .fontColor(Color.White)
              .placeholderColor(Color.White)
              .padding({ left: 10 })
              .onChange(v => this.username = v)
          }

          Row() {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(20)
              .fontColor([Color.White])
              .margin({ right: 10 })

            TextInput({
              text: this.password,
              placeholder: "请输入密码"
            })
              .type(InputType.Password)
              .layoutWeight(1)
              .height(45)
              .borderRadius(10)
              .backgroundColor($r('app.color.login_input_bg'))
              .fontColor(Color.White)
              .placeholderColor(Color.White)
              .padding({ left: 10 })
              .onChange(v => this.password = v)
          }


          Button(this.isLoggingIn ? "登录中..." : "登录")
            .width('100%')
            .constraintSize({
              minWidth: 280,
              maxWidth: 420
            })
            .height(50)
            .borderRadius(12)
            .backgroundColor($r('app.color.login_button_bg'))
            .backdropBlur(15)
            .fontColor(Color.White)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .enabled(!this.isLoggingIn)
            .opacity(this.isLoggingIn ? 0.7 : 1)
            .onClick(() => {
              if (!this.isSelect) {
                ToastUtil.showToast("请先阅读并同意用户协议和隐私政策！");
                return;
              }

              if (!this.username.trim() || !this.password.trim()) {
                ToastUtil.showToast("用户名或密码不能为空");
                return;
              }

              this.login()
            })

          Row() {
            Text("还没有账号?")
              .fontSize(14)
              .fontColor(Color.White)

            Text(" 去注册 >")
              .fontSize(14)
              .fontColor($r('app.color.login_highlight'))
              .fontWeight(FontWeight.Bold)
              .onClick(() =>{
                this.getUIContext().getRouter().pushUrl({
                  url: "pages/Register"
                }).catch((err:Error) => {
                  ToastUtil.showToast("[系统错误] 无法跳转至注册页面！")
                  LogUtil.error(`[跳转] 失败 | 错误:${"\n"}${JSON.stringify(err , null, 4)}`)
                })
              })
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: 5 })
        }
        .padding(25)
        .width('90%')
        .constraintSize({ minWidth: 280, maxWidth: 420 })
        .backgroundColor($r('app.color.login_card_bg'))
        .borderRadius(20)
        .alignItems(HorizontalAlign.Center)

        Row() {
          Checkbox()
            .select(this.isSelect)
            .margin({ right: 8 })
            .onChange(v => this.isSelect = v)

          Text("已阅读并同意 ")
            .fontSize(12)
            .fontColor(Color.White)

          Text("用户协议")
            .fontSize(12)
            .fontColor($r('app.color.login_highlight'))
            .onClick(() => {

            })

          Text(" 和 ")
            .fontSize(12)
            .fontColor(Color.White)

          Text("隐私政策")
            .fontSize(12)
            .fontColor($r('app.color.login_highlight'))
            .onClick(() => {

            })
        }
        .margin({ top: 30 })

        Blank().layoutWeight(1)

        Text("PetPlus宠家，您的家庭小助手。")
          .fontSize(12)
          .fontColor(Color.White)
          .opacity(0.9)
          .margin({ bottom: 25 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  async login() {

    if (this.isLoggingIn) return;
    this.isLoggingIn = true;

    await petsUserLogin({
      userName: this.username.trim(),
      psd: this.password.trim()
    }).then(res => {
      LogUtil.info(`[登录] 成功 | 响应:${"\n"}${JSON.stringify(res , null, 4)}`);

      PreferencesUtil.putSync("login_username", this.username.trim());
      PreferencesUtil.putSync("login_password", this.password.trim());
      PreferencesUtil.putSync("user_info", JSON.stringify(res));

      ToastUtil.showToast("登录成功");
      this.navigateToAppPage();
    }).catch((err: ApiError) =>{
      LogUtil.error(`[登录] 失败 | 错误:${"\n"}${JSON.stringify(err , null, 4)}`);
      ToastUtil.showToast(`登录失败：${err.message || '账号或密码错误'}`);

      PreferencesUtil.deleteSync("login_username");
      PreferencesUtil.deleteSync("login_password");
    }).finally(() => {

      this.isLoggingIn = false;
    });
  }

  private navigateToAppPage() {
    this.getUIContext().getRouter().pushUrl({
      url: "pages/AppPage"
    }).catch((err: Error) => {
      ToastUtil.showToast("[系统错误] 无法跳转到主页面！");
      LogUtil.error(`[跳转] 失败 | 错误:${"\n"}${JSON.stringify(err, null, 4)}`);
    });
  }
}