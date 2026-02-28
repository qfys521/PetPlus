import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { UserBean } from '../api/types';

@Entry
@Component
struct MyPage {
  @State userName: string = "未登录";
  @State email: string = "未绑定邮箱";
  @State phone: string = "未绑定手机号";

  // ��面生命周期：获取本地缓存的用户数据
  aboutToAppear() {
    this.loadUserInfo();
  }

  // 加载本地用户信息
  private loadUserInfo() {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userName = userInfo.userName || this.userName;
        this.email = userInfo.email || this.email;
        this.phone = userInfo.phoneNumber || this.phone;
      }
    } catch (e) {
      LogUtil.error("解析用户信息失败: " + e);
    }
  }

  build() {
    Stack() {
      // ===== 1. 底层背景图 =====
      Image($r('app.media.bg1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // ===== 2. 玻璃毛玻璃模糊层 =====
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.login_blur_layer'))
        .backdropBlur(25)

      // ===== 3. 主体内容 =====
      Column() {
        // --- 顶部透明导航栏 ---
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
            .margin({ right: 28 }) // 保持标题居中（抵消左侧图标的宽度）
        }
        .width('100%')
        .height(56)
        .padding({ left: 15, right: 15 })

        Scroll() {
          Column() {
            // --- 用户信息液态玻璃卡片 ---
            Row() {
              // 头像
              Image($r('app.media.touxiang2'))
                .width(70)
                .height(70)
                .borderRadius(35)
                .margin({ right: 15 })
                .border({ width: 2, color: 'rgba(255,255,255,0.3)' }) // 增加玻璃高光边框

              // 用户文本信息
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

              // 右侧箭头
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(24)
                .fontColor(['rgba(255,255,255,0.6)'])
            }
            .width('90%')
            .padding(20)
            .margin({ top: 15, bottom: 25 })
            .backgroundColor($r('app.color.login_card_bg')) // 使用统一半透明卡片背景
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.15)' }) // 增加玻璃边缘反光
            .backdropBlur(15) // 局部额外模糊增强质感
            .onClick(() => {
              ToastUtil.showToast("跳转到修改用户信息页面");
            })

            // --- 功能菜单液态玻璃卡片 ---
            Column() {
              this.MenuItem('sys.symbol.person_crop_circle_badge_exclamationmark', "修改个人信息", () => {
                ToastUtil.showToast("跳转到修改信息页面");
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.gearshape', "应用设置", () => {
                ToastUtil.showToast("跳转到应用设置页面");
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.trash', "清除缓存", () => {
                ToastUtil.showToast("缓存已清除");
              })

              Divider().color('rgba(255,255,255,0.15)').strokeWidth(1).margin({ left: 50, right: 15 })

              this.MenuItem('sys.symbol.info_circle', "关于 PetPlus宠家", () => {
                ToastUtil.showToast("关于我们");
              })
            }
            .width('90%')
            .backgroundColor($r('app.color.login_card_bg'))
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.15)' })
            .backdropBlur(15)

            Blank().layoutWeight(1)

            // --- 退出登录按钮 (红色玻璃态) ---
            Button("退出登录")
              .width('90%')
              .height(52)
              .backgroundColor('rgba(255, 77, 79, 0.25)') // 半透明红色背景
              .fontColor('#FF6B6B') // 亮红色字体
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .borderRadius(14)
              .border({ width: 1, color: 'rgba(255, 77, 79, 0.4)' }) // 红色玻璃边框
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
  }

  // ===== 自定义菜单项 Builder (适配深色/玻璃态) =====
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
        .fontColor(['rgba(255,255,255,0.5)']) // 半透明白色箭头
    }
    .width('100%')
    .height(65)
    .padding({ left: 15, right: 15 })
    .backgroundColor(Color.Transparent) // 继承父容器的玻璃背景
    .onClick(onClick)
  }

  // ===== 退出登录二次确认弹窗 =====
  private showLogoutDialog() {
    this.getUIContext().showAlertDialog({
      title: "退出登录",
      message: "确认要退出当前账号吗？",
      primaryButton: {
        value: "取消",
        action: () => {
          LogUtil.info("用户取消退出");
        }
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

  // ===== 退出登录核心逻辑 =====
  private logout() {
    PreferencesUtil.deleteSync("login_username");
    PreferencesUtil.deleteSync("login_password");
    PreferencesUtil.deleteSync("user_info");

    ToastUtil.showToast("已退出登录");

    const router = this.getUIContext().getRouter();
    router.replaceUrl({
      url: "pages/Index"
    }).then(() => {
      router.clear();
    }).catch((err: Error) => {
      LogUtil.error(`退出跳转失败: ${JSON.stringify(err)}`);
    });
  }
}