import { LogUtil } from '@pura/harmony-utils';
import { IntelCategory, knowledgeData } from '../data/knowledge';
import { display } from '@kit.ArkUI';

// 引入设备显示模块，用于获取真实屏幕尺寸

@Component
export struct Intel {
  // 核心控制变量：是否为移动端布局
  @State isMobileLayout: boolean = true;

  // 控制“回到顶部”按钮的显示
  @State showScrollToTop: boolean = false;
  // 给主要的 Scroll/List 绑定控制器，用于跳转顶部
  private scroller: Scroller = new Scroller();

  // 原始数据
  private allData: IntelCategory[] = [];
  // 视图绑定的数据
  @State displayData: IntelCategory[] = [];

  @State searchKeyword: string = '';
  @State isSearching: boolean = true;
  private searchDebounceTimer: number = -1;

  // 记录哪些分类处于展开状态
  @State expandedCategories: string[] = [];

  // PC平板端左侧分类边栏的列表
  @State categoryList: string[] = ['全部'];
  @State selectedCategory: string = '全部';

  aboutToAppear(): void {
    // 1. 获取真实屏幕物理宽度，防止布局误判
    try {
      const displayObj = display.getDefaultDisplaySync();
      // 获取物理像素并转为逻辑像素 vp，或者简单比较宽高
      if (displayObj.width < displayObj.height || displayObj.width < 1500) {
        // 通常竖屏(宽<高)绝对是手机。或者物理像素宽度不够大也是手机。
        this.isMobileLayout = true;
      } else {
        this.isMobileLayout = false;
      }
    } catch (e) {
      LogUtil.error("[Intel] 获取屏幕信息失败，默认使用移动端布局");
      this.isMobileLayout = true;
    }

    setTimeout((): void => {
      this.initData();
    }, 50);
  }

  private initData(): void {
    try {
      this.allData = knowledgeData as IntelCategory[];
      this.displayData = this.allData;

      const cats: string[] = ['全部'];
      this.allData.forEach((item: IntelCategory): void => {
        cats.push(this.extractShortTitle(item.title));
      });
      this.categoryList = cats;

      // 如果是 PC，默认展开第一个
      if (!this.isMobileLayout && this.allData.length > 0) {
        this.expandedCategories = [this.allData[0].title];
      }

      this.isSearching = false;
    } catch (e) {
      LogUtil.error("[Intel] 加载静态数据失败");
      this.isSearching = false;
    }
  }

  // === 展开与折叠 ===
  private toggleCategory(title: string): void {
    const index = this.expandedCategories.indexOf(title);
    if (index >= 0) {
      this.expandedCategories.splice(index, 1);
    } else {
      this.expandedCategories.push(title);
    }
  }

  private isExpanded(title: string): boolean {
    return this.expandedCategories.indexOf(title) >= 0;
  }

  // === 搜索与过滤 ===
  private handleSearchFilter(): void {
    this.isSearching = true;

    if (this.searchDebounceTimer !== -1) {
      clearTimeout(this.searchDebounceTimer);
    }

    this.searchDebounceTimer = setTimeout((): void => {
      new Promise<IntelCategory[]>((resolve: (res: IntelCategory[]) => void): void => {
        let result: IntelCategory[] = this.allData;

        // 只有非移动端才受左侧侧��栏影响
        if (!this.isMobileLayout && this.selectedCategory !== '全部') {
          result = result.filter((item: IntelCategory): boolean => this.extractShortTitle(item.title) === this.selectedCategory);
        }

        const kw = this.searchKeyword.trim().toLowerCase();

        if (kw.length > 0) {
          result = result.map((category: IntelCategory): IntelCategory => {
            const titleMatches = category.title.toLowerCase().includes(kw);
            const matchedSentences = category.subSentences.filter((sentence: string): boolean =>
            sentence.toLowerCase().includes(kw)
            );

            // 如果有搜索词，自动展开匹配的分类
            if (titleMatches || matchedSentences.length > 0) {
              if (this.expandedCategories.indexOf(category.title) === -1) {
                this.expandedCategories.push(category.title);
              }
            }

            return {
              title: category.title,
              subSentences: titleMatches ? category.subSentences : matchedSentences
            } as IntelCategory;
          }).filter((category: IntelCategory): boolean => category.subSentences.length > 0);
        }

        resolve(result);
      }).then((filteredData: IntelCategory[]): void => {
        this.displayData = filteredData;
        this.isSearching = false;
      });
    }, 300);
  }

  private onSearchChange(val: string): void {
    this.searchKeyword = val;
    this.handleSearchFilter();
  }

  private onCategorySelect(cat: string): void {
    if (this.selectedCategory === cat) return;
    this.selectedCategory = cat;

    if (cat !== '全部') {
      const target = this.allData.find(item => this.extractShortTitle(item.title) === cat);
      if (target && this.expandedCategories.indexOf(target.title) === -1) {
        this.expandedCategories = [target.title];
      }
    }
    this.handleSearchFilter();
  }

  private extractShortTitle(fullTitle: string): string {
    if (!fullTitle) return "其他";
    let cleanTitle = fullTitle.replace(/^[一二三四五六七八九十]+、/, '');
    cleanTitle = cleanTitle.replace(/（.*?）/g, '');
    cleanTitle = cleanTitle.replace(/篇/g, '');
    return cleanTitle;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image($r('app.media.bg2'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(255, 255, 255, 0.4)')

        Column() {
          this.HeaderSection()

          if (this.isMobileLayout) {
            // 【移动端】：全屏宽度，折叠卡片上下排列
            Stack({ alignContent: Alignment.Center }) {
              this.ContentList()
              if (this.isSearching) this.LoadingIndicator()
            }
            .layoutWeight(1)
            .width('100%')
          } else {
            // 【PC/平板端】：左右双栏布局
            Row() {
              Column() {
                this.DesktopCategorySidebar()
              }
              .width(220)
              .height('100%')
              .margin({ right: 16 })

              Stack({ alignContent: Alignment.Center }) {
                this.ContentList()
                if (this.isSearching) this.LoadingIndicator()
              }
              .layoutWeight(1)
              .height('100%')
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16, bottom: 20 })
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      // 使用更可靠的窗口拉伸监听作为补充
      .onAreaChange((oldValue: Area, newValue: Area) => {
        const w = newValue.width as number;
        const h = newValue.height as number;
        const isNowMobile = (w < 600 || h > w);
        if (this.isMobileLayout !== isNowMobile) {
          this.isMobileLayout = isNowMobile;
          this.handleSearchFilter();
        }
      })

      // === 悬浮的回到顶部按钮 ===
      if (this.showScrollToTop) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.arrow_up'))
            .fontSize(24)
            .fontColor(['#FFFFFF'])
        }
        .width(48)
        .height(48)
        .backgroundColor('#1890FF')
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.2)', offsetY: 4 })
        .margin({ right: 24, bottom: 40 })
        .transition({ type: TransitionType.All, opacity: 1, scale: { x: 0, y: 0 } })
        .onClick((): void => {
          // 调用 Scroller 动画滚动到列表最顶部
          this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300, curve: Curve.EaseInOut } });
        })
      }
    }
  }

  @Builder
  private HeaderSection(): void {
    Column({ space: 16 }) {
      Text("📖 养宠智库")
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .margin({ top: 20, left: 16 })

      Search({ placeholder: "输入关键词检索海量养宠知识..." })
        .width('90%')
        .height(40)
        .backgroundColor('rgba(255, 255, 255, 0.7)')
        .borderRadius(20)
        .onChange((value: string): void => {
          this.onSearchChange(value);
        })
    }
    .width('100%')
    .padding({ bottom: 16 })
  }

  @Builder
  private DesktopCategorySidebar(): void {
    Scroll() {
      Column({ space: 8 }) {
        Text("知识分类")
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Black)
          .width('100%').padding({ left: 12, bottom: 8 })

        ForEach(this.categoryList, (cat: string) => {
          Row() {
            Text(cat)
              .fontSize(14)
              .fontWeight(this.selectedCategory === cat ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedCategory === cat ? '#1890FF' : '#555')
          }
          .width('100%').padding(12)
          .backgroundColor(this.selectedCategory === cat ? 'rgba(24, 144, 255, 0.15)' : 'transparent')
          .borderRadius(12)
          .onClick((): void => {
            this.onCategorySelect(cat);
          })
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.75)')
      .borderRadius(20)
    }
    .height('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  private ContentList(): void {
    if (this.displayData.length === 0 && !this.isSearching) {
      Column({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass')).fontSize(60).fontColor(['#CCC'])
        Text("未找到相关知识").fontSize(14).fontColor('#888')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      // 绑定 Scroller，监听滚动事件来控制“回到顶部”的显隐
      List({ space: 16, scroller: this.scroller }) {
        ForEach(this.displayData, (category: IntelCategory) => {
          ListItem() {
            this.CategoryFoldCard(category)
          }
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .padding({ left: this.isMobileLayout ? 16 : 0, right: this.isMobileLayout ? 16 : 0, bottom: 20 })
      .onScroll((xOffset: number, yOffset: number): void => {
        // 获取当前滚动的总偏移量，若大于300则显示按钮，否则隐藏
        const y = this.scroller.currentOffset().yOffset;
        if (y > 300 && !this.showScrollToTop) {
          animateTo({ duration: 200 }, (): void => { this.showScrollToTop = true; });
        } else if (y <= 300 && this.showScrollToTop) {
          animateTo({ duration: 200 }, (): void => { this.showScrollToTop = false; });
        }
      })
    }
  }

  @Builder
  private CategoryFoldCard(category: IntelCategory): void {
    Column() {
      // 头部点击区
      Row() {
        SymbolGlyph($r('sys.symbol.doc_text')).fontSize(20).fontColor(['#1890FF']).margin({ right: 12 })

        Column({ space: 4 }) {
          Text(this.extractShortTitle(category.title))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Text(`共 ${category.subSentences.length} 条知识`)
            .fontSize(12)
            .fontColor('#888')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph(this.isExpanded(category.title) ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(20)
          .fontColor(['#999'])
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.85)')
      .borderRadius(this.isExpanded(category.title) ? { topLeft: 16, topRight: 16, bottomLeft: 0, bottomRight: 0 } : 16)
      .onClick((): void => {
        this.toggleCategory(category.title);
      })

      // 展开内容区
      if (this.isExpanded(category.title)) {
        Column({ space: 12 }) {
          ForEach(category.subSentences, (sentence: string) => {
            Row() {
              Circle({ width: 6, height: 6 }).fill('#FFB11B').margin({ top: 8, right: 10 })
              Text(sentence)
                .fontSize(15)
                .fontColor('#444')
                .lineHeight(24)
                .layoutWeight(1)
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('rgba(255, 255, 255, 0.6)')
        .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 })
      }
    }
    .width('100%')
    .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)', radius: 16 })
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 4 })
    .margin({ bottom: this.isExpanded(category.title) ? 10 : 0 })
    .animation({ duration: 300, curve: Curve.EaseInOut })
  }

  @Builder
  private LoadingIndicator(): void {
    Column() {
      LoadingProgress().width(40).height(40)
      Text("正在检索...").fontSize(12).fontColor('#666').margin({ top: 8 })
    }
    .padding(20)
    .backgroundColor('rgba(255,255,255,0.8)')
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)' })
  }
}