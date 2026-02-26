import { LogUtil, ToastUtil } from '@pura/harmony-utils';
import { setUserinfo } from '../api/services';
import { ApiError } from '../api/types';

@Entry
@Component
struct register {

  @State username: string = "";
  @State password: string = "";
  @State confirmPassword: string = "";
  @State email: string = "";
  @State phone: string = "";
  @State isAgree: boolean = false;

  build() {
    Stack() {

      // ===== 背景 =====
      Image($r('app.media.bg1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // ===== 模糊层 =====
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.login_blur_layer'))
        .backdropBlur(25)

      // ===== 主体 =====
      Column() {

        Text("创建账号")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 110, bottom: 40 })

        Column({ space: 18 }) {

          // 用户名
          this.inputItem('person', "请输入用户名", this.username, v => this.username = v)

          // 邮箱
          this.inputItem('envelope', "请输入邮箱", this.email, v => this.email = v)

          // 手机号
          this.inputItem('phone', "请输入手机号", this.phone, v => this.phone = v)

          // 密码
          this.passwordItem("请输入密码", this.password, v => this.password = v)

          // 确认密码
          this.passwordItem("请确认密码", this.confirmPassword, v => this.confirmPassword = v)

          // 注册按钮
          Button("立即注册")
            .width('100%')
            .height(50)
            .borderRadius(14)
            .backgroundColor($r('app.color.login_button_bg'))
            .fontColor(Color.White)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
            .onClick(() => this.register())

          // 返回登录
          Row() {
            Text("已有账号?")
              .fontSize(14)
              .fontColor(Color.White)

            Text(" 去登录 >")
              .fontSize(14)
              .fontColor($r('app.color.login_highlight'))
              .fontWeight(FontWeight.Bold)
              .onClick(() =>{
                this.getUIContext().getRouter().back()
              })
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: 5 })

        }
        .padding(25)
        .width('90%')
        .constraintSize({ minWidth: 280, maxWidth: 420 })
        .backgroundColor($r('app.color.login_card_bg'))
        .borderRadius(22)
        .alignItems(HorizontalAlign.Center)

        // 协议
        Row() {
          Checkbox()
            .select(this.isAgree)
            .margin({ right: 8 })
            .onChange(v => this.isAgree = v)

          Text("我已阅读并同意用户协议与隐私政策")
            .fontSize(12)
            .fontColor(Color.White)
        }
        .margin({ top: 25 })

        Blank().layoutWeight(1)

        Text("PetPlus宠家 · 陪伴每一份温暖")
          .fontSize(12)
          .fontColor(Color.White)
          .opacity(0.85)
          .margin({ bottom: 25 })

      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  // ===== 通用输入框 =====
  @Builder
  private inputItem(icon: string, placeholder: string, value: string, onChange: (v: string) => void) {
    Row() {
      SymbolGlyph($r(`sys.symbol.${icon}`))
        .fontSize(20)
        .fontColor([Color.White])
        .margin({ right: 10 })

      TextInput({
        text: value,
        placeholder: placeholder
      })
        .layoutWeight(1)
        .height(45)
        .borderRadius(12)
        .backgroundColor($r('app.color.login_input_bg'))
        .fontColor(Color.White)
        .placeholderColor(Color.White)
        .padding({ left: 12 })
        .onChange(onChange)
    }
  }

  // ===== 密码输入框 =====
  @Builder
  private passwordItem(placeholder: string, value: string, onChange: (v: string) => void) {
    Row() {
      SymbolGlyph($r('sys.symbol.lock'))
        .fontSize(20)
        .fontColor([Color.White])
        .margin({ right: 10 })

      TextInput({
        text: value,
        placeholder: placeholder
      })
        .type(InputType.Password)
        .layoutWeight(1)
        .height(45)
        .borderRadius(12)
        .backgroundColor($r('app.color.login_input_bg'))
        .fontColor(Color.White)
        .placeholderColor(Color.White)
        .padding({ left: 12 })
        .onChange(onChange)
    }
  }

  // ===== 注册逻辑 =====
  async register() {

    if (!this.username || !this.password || !this.confirmPassword) {
      ToastUtil.showToast("请填写完整信息");
      return;
    }

    if (this.password !== this.confirmPassword) {
      ToastUtil.showToast("两次密码不一致");
      return;
    }

    if (!this.isAgree) {
      ToastUtil.showToast("请先同意用户协议");
      return;
    }

    await setUserinfo({
      userName: this.username.trim(),
      password: this.password.trim(),
      email: this.email.trim(),
      phoneNumber: this.phone.trim(),
      type: '0'
    })
      .then(res => {
        ToastUtil.showToast("注册成功");
        LogUtil.info(`[注册] 成功`);
      })
      .catch((err: ApiError) => {
        ToastUtil.showToast("注册失败");
        LogUtil.error(`[注册] 失败:${"\n"}${JSON.stringify(err, null, 4)}`);
      });
  }
}