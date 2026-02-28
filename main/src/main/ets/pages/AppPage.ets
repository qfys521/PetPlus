import { DeviceUtil, LogUtil } from '@pura/harmony-utils';
import { Dashboard } from '../pageview/Dashboard';
import { Health } from '../pageview/Health';
import { Asset } from '../pageview/Asset';
import { Intel } from '../pageview/Intel';
import { UIUtils } from '@kit.ArkUI';

interface BottomTabItemData {
  icon: Resource;
  title: string;
  index: number;
}

@Entry
@Component
struct AppPage {
  @State currentIndex: number = 0;
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
    { icon: $r('sys.symbol.creditcard'), title: '资产', index: 2 },
    { icon: $r('sys.symbol.book'), title: '智库', index: 3 }
  ];

  aboutToAppear(): void {
    LogUtil.info('[AppPage] 页面即将显示');
  }

  build() {
    // 1. 【布局修改】使用 Stack 将底部导航悬浮在页面内容之上
    Stack({ alignContent: Alignment.Bottom }) {
      // 主内容
      this.mainContent()

      // 底部导航（悬浮液态玻璃）
      this.bottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.login_blur_layer'))
  }

  // =========================
  // 主体内容
  // =========================
  @Builder
  private mainContent() {
    Column() {
      this.topAppBar()
      this.pageContentView()
    }
    .width('100%')
    .height('100%')
    // 2. 【细节处理】底部留出 Padding，防止最下方的页面内容被悬浮栏永久遮挡
    .padding({ left: 16, right: 16, top: 10, bottom: 100 })
  }

  // =========================
  // 顶部标题栏
  // =========================
  @Builder
  private topAppBar() {
    Row() {
      Row() {
        // 示例：在 AppPage.ets 中点击头像的逻辑
        Image($r('app.media.touxiang2'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: "pages/MyPage"
            });
          })

        Column() {
          Text("欢迎回来")
            .fontSize(12)
            .fontColor($r('app.color.login_text_primary'))
            .opacity(0.8)

          Text("PetPlus用户")
            .fontSize(14)
            .fontColor($r('app.color.login_text_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      SymbolGlyph($r('sys.symbol.gearshape'))
        .fontSize(22)
        .fontColor([$r('app.color.login_text_primary')])
        .onClick(() => {
          LogUtil.info('[AppPage] 点击设置按钮');
        })
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
      TabContent() { Asset() }
      TabContent() { Intel() }
    }
    .animationDuration(300)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .layoutWeight(1)
    .barPosition(BarPosition.End)
    // 3. 【核心修复】将默认 TabBar 高度设为 0，彻底解决“幽灵按钮”问题！
    .barHeight(0)
  }

  // =========================
  // 底部导航栏 (悬浮液态玻璃设计)
  // =========================
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
    .width('90%') // 缩小宽度，让两侧留白
    .height(72)   // 稍微改薄一点，更像胶囊
    .margin({ bottom: 24 }) // 底部悬浮距离
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    // 4. 【材质修改】半透明底色 + 极简背景模糊
    .backgroundColor('rgba(26, 26, 46, 0.65)') // 保持你原有的深色调，但改为65%透明度
    .backgroundBlurStyle(BlurStyle.Regular) // 开启毛玻璃效果
    .borderRadius(36) // 大圆角实现 (二二二二) 形状
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.25)', // 让阴影更柔和一点，凸显玻璃的质感
      offsetX: 0,
      offsetY: 8
    })
  }

  // =========================
  // 单个Tab
  // =========================
  @Builder
  private bottomTabItem(icon: Resource, title: string, index: number) {
    Column({ space: 4 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor(
          this.currentIndex === index
            ? [$r('app.color.login_highlight')]
            : [$r('app.color.login_text_primary')]
        )
        .opacity(this.currentIndex === index ? 1 : 0.7)

      Text(title)
        .fontSize(11)
        .fontColor(
          this.currentIndex === index
            ? $r('app.color.login_highlight')
            : $r('app.color.login_text_primary')
        )
        .opacity(this.currentIndex === index ? 1 : 0.7)
        .maxLines(1)
    }
    .width(60)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale({
      x: this.currentIndex === index ? 1.1 : 1,
      y: this.currentIndex === index ? 1.1 : 1
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
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