import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { UserBean } from '../api/types';
import { setUserinfo } from '../api/services';




@CustomDialog
struct EditUserInfoDialog {
  controller?: CustomDialogController


  @Link editName: string;
  @Link editEmail: string;
  @Link editPhone: string;
  @Link editAddress: string;
  @Link editPass: string;
  @Link isUpdating: boolean;


  confirmAction: () => void = () => {}

  build() {
    Column({ space: 18 }) {
      Text("修改个人信息")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ bottom: 5, top: 10 })

      this.InputRow('person', '用户名 (必填)', this.editName, (v) => this.editName = v)
      this.InputRow('lock', '登录密码 (必填)', this.editPass, (v) => this.editPass = v, true)
      this.InputRow('envelope', '邮箱地址', this.editEmail, (v) => this.editEmail = v)
      this.InputRow('phone', '手机号码', this.editPhone, (v) => this.editPhone = v)
      this.InputRow('house', '家庭住址', this.editAddress, (v) => this.editAddress = v)

      Row({ space: 15 }) {
        Button("取消")
          .layoutWeight(1)
          .height(45)
          .backgroundColor('rgba(255, 255, 255, 0.15)')
          .fontColor(Color.White)
          .onClick(() => {
            this.controller?.close();
          })

        Button(this.isUpdating ? "保存��..." : "保存修改")
          .layoutWeight(1)
          .height(45)
          .backgroundColor('rgba(255, 255, 255, 0.9)')
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Bold)
          .enabled(!this.isUpdating)
          .opacity(this.isUpdating ? 0.6 : 1)
          .onClick(() => {
            this.confirmAction();
          })
      }
      .width('100%')
      .margin({ top: 15, bottom: 5 })
    }
    .padding(25)
    .width('90%')

    .backgroundColor('rgba(40, 40, 50, 0.65)')
    .backgroundBlurStyle(BlurStyle.Thick)
    .borderRadius(24)
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.25)' })
  }

  @Builder
  private InputRow(icon: string, placeholder: string, value: string, onChange: (v: string) => void, isPwd = false) {
    Row() {
      SymbolGlyph($r(`sys.symbol.${icon}`))
        .fontSize(20)
        .fontColor(['rgba(255, 255, 255, 0.8)'])
        .margin({ right: 12 })

      TextInput({ text: value, placeholder: placeholder })
        .type(isPwd ? InputType.Password : InputType.Normal)
        .layoutWeight(1)
        .height(42)
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .fontColor(Color.White)
        .placeholderColor('rgba(255, 255, 255, 0.4)')
        .borderRadius(10)
        .padding({ left: 12 })
        .onChange(onChange)
    }
  }
}




@Entry
@Component
struct MyPage {

  @State userName: string = "未登录";
  @State email: string = "未绑定邮箱";
  @State phone: string = "未绑定手机号";
  @State homeAddress: string = "未设置家庭地址";
  @State userKey: string = "";


  @State editName: string = '';
  @State editEmail: string = '';
  @State editPhone: string = '';
  @State editAddress: string = '';
  @State editPass: string = '';
  @State isUpdating: boolean = false;


  dialogController: CustomDialogController = new CustomDialogController({
    builder: EditUserInfoDialog({
      editName: $editName,
      editEmail: $editEmail,
      editPhone: $editPhone,
      editAddress: $editAddress,
      editPass: $editPass,
      isUpdating: $isUpdating,
      confirmAction: () => { this.handleUpdateUserInfo() }
    }),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  aboutToAppear() {
    this.loadUserInfo();
  }


  private loadUserInfo() {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userName = userInfo.userName || this.userName;
        this.email = userInfo.email || this.email;
        this.phone = userInfo.phoneNumber || this.phone;
        this.homeAddress = userInfo.homeAddress || this.homeAddress;
        this.userKey = userInfo.key || "";
      }
    } catch (e) {
      LogUtil.error("解析用户信息失败: " + e);
    }
  }


  private openEditDialog() {
    if (!this.userKey) {
      ToastUtil.showToast("用户认证失效，请重新登录");
      return;
    }


    this.editName = this.userName === "未登录" ? "" : this.userName;
    this.editEmail = this.email === "未绑定邮箱" ? "" : this.email;
    this.editPhone = this.phone === "未绑定手机号" ? "" : this.phone;
    this.editAddress = this.homeAddress === "未设置家庭地址" ? "" : this.homeAddress;

    this.editPass = PreferencesUtil.getStringSync("login_password", "");

    this.dialogController.open();
  }


  private async handleUpdateUserInfo() {
    if (!this.editName.trim() || !this.editPass.trim()) {
      ToastUtil.showToast("用户名和密码不能为空");
      return;
    }

    this.isUpdating = true;
    try {

      await setUserinfo({
        userName: this.editName.trim(),
        password: this.editPass.trim(),
        email: this.editEmail.trim(),
        phoneNumber: this.editPhone.trim(),
        homeAddress: this.editAddress.trim(),
        type: '1',
        key: this.userKey
      });

      ToastUtil.showToast("信息修改成功");


      this.userName = this.editName.trim();
      this.email = this.editEmail.trim() || "未绑定邮箱";
      this.phone = this.editPhone.trim() || "未绑定手机号";
      this.homeAddress = this.editAddress.trim() || "未设置家庭地址";


      const userInfoStr = PreferencesUtil.getStringSync("user_info", "{}");
      const userInfo: UserBean = JSON.parse(userInfoStr);
      userInfo.userName = this.userName;
      userInfo.email = this.editEmail.trim();
      userInfo.phoneNumber = this.editPhone.trim();
      userInfo.homeAddress = this.editAddress.trim();

      PreferencesUtil.putSync("user_info", JSON.stringify(userInfo));
      PreferencesUtil.putSync("login_username", this.userName);
      PreferencesUtil.putSync("login_password", this.editPass.trim());


      this.dialogController.close();

    } catch (err) {
      LogUtil.error(`修改信息失败: ${JSON.stringify(err)}`);
      ToastUtil.showToast(`修改失败: ${err.message || '网络异常'}`);
    } finally {
      this.isUpdating = false;
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
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(28)
            .fontColor([Color.White])
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })

          Text("个人中心")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 28 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 15, right: 15 })
        .margin({ top: 40 })

        Scroll() {
          Column() {

            Row() {
              Image($r('app.media.touxiang2'))
                .width(70)
                .height(70)
                .borderRadius(35)
                .margin({ right: 15 })
                .border({ width: 2, color: 'rgba(255,255,255,0.3)' })

              Column({ space: 8 }) {
                Text(this.userName)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)

                Text(`手机号: ${this.phone}`)
                  .fontSize(13)
                  .fontColor('rgba(255,255,255,0.8)')

                Text(`邮箱: ${this.email}`)
                  .fontSize(13)
                  .fontColor('rgba(255,255,255,0.8)')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(24)
                .fontColor(['rgba(255,255,255,0.6)'])
            }
            .width('90%')
            .padding(20)
            .margin({ top: 15, bottom: 25 })
            .backgroundColor($r('app.color.login_card_bg'))
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.15)' })
            .backdropBlur(15)
            .onClick(() => {

              this.openEditDialog();
            })


            Column() {
              this.MenuItem('sys.symbol.person_crop_circle_badge_exclamationmark', "修改个人信息", () => {
                this.openEditDialog();
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.gearshape', "应用设置", () => {
                ToastUtil.showToast("功能开发中...");
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.trash', "清除缓存", () => {
                ToastUtil.showToast("缓存已清除");
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.info_circle', "关于 PetPlus宠家", () => {
                ToastUtil.showToast("当前版本 v1.0.0");
              })
            }
            .width('90%')
            .backgroundColor($r('app.color.login_card_bg'))
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.15)' })
            .backdropBlur(15)

            Blank().layoutWeight(1)


            Button("退出登录")
              .width('90%')
              .height(52)
              .backgroundColor('rgba(255, 77, 79, 0.25)')
              .fontColor('#FF6B6B')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .borderRadius(14)
              .border({ width: 1, color: 'rgba(255, 77, 79, 0.4)' })
              .backdropBlur(15)
              .margin({ top: 40, bottom: 40 })
              .onClick(() => {
                this.showLogoutDialog();
              })
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private MenuItem(iconName: string, title: string, onClick: () => void) {
    Row() {
      SymbolGlyph($r(iconName))
        .fontSize(22)
        .fontColor([Color.White])
        .margin({ right: 15 })

      Text(title)
        .fontSize(15)
        .fontColor(Color.White)
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor(['rgba(255,255,255,0.5)'])
    }
    .width('100%')
    .height(65)
    .padding({ left: 15, right: 15 })
    .backgroundColor(Color.Transparent)
    .onClick(onClick)
  }

  private showLogoutDialog() {
    this.getUIContext().showAlertDialog({
      title: "退出登录",
      message: "确认要退出当前账号吗？",
      primaryButton: {
        value: "取消",
        action: () => {}
      },
      secondaryButton: {
        value: "确认退出",
        fontColor: '#FF4D4F',
        action: () => {
          this.logout();
        }
      }
    });
  }

  private logout() {
    PreferencesUtil.deleteSync("login_username");
    PreferencesUtil.deleteSync("login_password");
    PreferencesUtil.deleteSync("user_info");

    ToastUtil.showToast("已退出登录");

    const router = this.getUIContext().getRouter();
    router.replaceUrl({ url: "pages/Index" }).then(() => {
      router.clear();
    }).catch((err: Error) => {
      LogUtil.error(`退出跳转失败: ${JSON.stringify(err)}`);
    });
  }
}