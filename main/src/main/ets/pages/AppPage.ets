import { DeviceUtil, LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { Dashboard } from '../pageview/Dashboard';
import { Health } from '../pageview/Health';
import { UserBean } from '../api/types';
import { Archival } from '../pageview/Archival';
import { Intel } from '../pageview/Intel';

interface BottomTabItemData {
  icon: Resource;
  title: string;
  index: number;
}

@Entry
@Component
struct AppPage {
  @State currentIndex: number = 0;

  @State userName: string = "用户";

  private tabController: TabsController = new TabsController();

  private readonly pageTitleMap: Map<number, string> = new Map([
    [0, '智能看板'],
    [1, '精密健康'],
    [2, '用户资产'],
    [3, '智库文档']
  ]);

  private readonly bottomItems: BottomTabItemData[] = [
    { icon: $r('sys.symbol.house'), title: '首页', index: 0 },
    { icon: $r('sys.symbol.heart'), title: '健康', index: 1 },
    { icon: $r('sys.symbol.creditcard'), title: '管理', index: 2 },
    { icon: $r('sys.symbol.book'), title: '智库', index: 3 }
  ];

  aboutToAppear(): void {
    LogUtil.info('[AppPage] 页面即将显示');
    this.loadUserInfo();
  }


  private loadUserInfo() {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userName = userInfo.userName || this.userName;
      }
    } catch (e) {
      LogUtil.error("解析用户信息失败: " + e);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {

      Image($r('app.media.bg2'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)


      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255, 255, 255, 0.15)')
        .backdropBlur(30)


      this.mainContent()


      this.bottomTabBar()
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }




  @Builder
  private mainContent() {
    Column() {
      this.topAppBar()
      this.pageContentView()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 100 })
  }




  @Builder
  private topAppBar() {
    Row() {
      Row() {
        Image($r('app.media.touxiang2'))
          .width(42)
          .height(42)
          .borderRadius(21)
          .border({ width: 1.5, color: Color.White })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pageview/MyPage'
            }).catch((err: Error) => {
              ToastUtil.showToast("[系统错误] 无法跳转到设置页面！");
              LogUtil.error(`[跳转] 失败 | 错误:${"\n"}${JSON.stringify(err, null, 4)}`);
            });
          })

        Column() {
          Text("欢迎回来")
            .fontSize(12)
            .fontColor('#666666')


          Text(this.userName)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)


    }
    .height(60)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  private pageContentView() {
    Tabs({
      controller: this.tabController
    }) {
      TabContent() { Dashboard() }
      TabContent() { Health() }
      TabContent() { Archival() }
      TabContent() { Intel() }
    }
    .animationDuration(300)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .layoutWeight(1)
    .barPosition(BarPosition.End)
    .barHeight(0)
  }




  @Builder
  private bottomTabBar() {
    Row() {
      ForEach(
        this.bottomItems,
        (item: BottomTabItemData) => {
          this.bottomTabItem(item.icon, item.title, item.index)
        },
        (item: BottomTabItemData) => item.index.toString()
      )
    }
    .width('90%')
    .height(72)
    .margin({ bottom: 34 })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)

    .backgroundColor('rgba(255, 255, 255, 0.45)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .borderRadius(36)
    .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.6)' })
    .shadow({
      radius: 15,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }




  @Builder
  private bottomTabItem(icon: Resource, title: string, index: number) {
    Column({ space: 4 }) {
      SymbolGlyph(icon)
        .fontSize(22)

        .fontColor(this.currentIndex === index ? [Color.Black] : ['#888888'])
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)

      Text(title)
        .fontSize(11)

        .fontColor(this.currentIndex === index ? Color.Black : '#888888')
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .maxLines(1)
    }
    .width(60)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale({
      x: this.currentIndex === index ? 1.15 : 1,
      y: this.currentIndex === index ? 1.15 : 1
    })
    .animation({
      duration: 250,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      if (this.currentIndex !== index) {
        this.currentIndex = index;
        this.tabController.changeIndex(index);
        LogUtil.info(`[AppPage] 点击底部Tab: ${title}`);
      }
    })
  }
}