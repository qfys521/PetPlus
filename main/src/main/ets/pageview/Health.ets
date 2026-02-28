import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { getPets, getPetHealthHistory } from '../api/services';
import { McLineChart, McPieChart, Options } from '@mcui/mccharts';
import {
  PetBean,
  UserBean,
  GetPetHealthHistoryRequest,
  PetHealthHistory
} from '../api/types';


export class PieChartData {
  value: number = 0;
  name: string = '';
  constructor(value: number, name: string) {
    this.value = value;
    this.name = name;
  }
}

@Component
export struct Health {

  @State currentBreakpoint: string = 'sm';
  @State userKey: string = '';

  @State petInfo: PetBean | null = null;
  @State healthHistoryList: PetHealthHistory[] = [];


  @State isLoading: boolean = true;
  @State isError: boolean = false;



  @State lineOption: Options = new Options({
    xAxis: { data: ['--'] },
    yAxis: [
      { name: '体温(℃)' },
      { name: '体重(kg)' }
    ],
    series: [
      { name: '体温', type: 'line', data: [0] },
      { name: '体重', type: 'line', yAxisIndex: 1, data: [0] }
    ]
  });


  @State pieOption: Options = new Options({
    series: [{
      data: [
        new PieChartData(1, '暂无数据')
      ]
    }]
  });

  aboutToAppear() {
    this.initData();
  }


  private extractNumber(str: string | undefined): number {
    if (!str) return 0;
    const match = str.match(/-?\d+(\.\d+)?/);
    return match ? Number(match[0]) : 0;
  }


  private formatTime(d: Date): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  private initData() {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userKey = userInfo.key || "";
      }
    } catch (e) {
      LogUtil.error("[Health] 解析本地用户信息失败");
    }

    if (!this.userKey) {
      ToastUtil.showToast("身份验证失败，请重新登录");
      this.isError = true;
      this.isLoading = false;
      return;
    }

    this.isLoading = true;
    const now = new Date();

    const halfYearAgo = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);


    getPets(this.userKey).then((res: Object) => {
      if (Array.isArray(res) && res.length > 0) {
        this.petInfo = res[0] as PetBean;
      } else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list']) && resRecord['list'].length > 0) {
          this.petInfo = resRecord['list'][0] as PetBean;
        }
      }
    }).catch(() => {

      this.petInfo = {
        petName: "布丁",
        petSpecies: "猫",
        petBreed: "英短",
        currentWeight: 4.5,
        healthStatus: "健康"
      } as PetBean;
    });


    const historyParams: GetPetHealthHistoryRequest = {
      key: this.userKey,
      petId: "1",
      startTime: this.formatTime(halfYearAgo),
      endTime: this.formatTime(now),
      page: "1",
      size: "20"
    };

    getPetHealthHistory(historyParams).then((res: Object) => {
      let dataArray: PetHealthHistory[] = [];
      if (Array.isArray(res)) {
        dataArray = res as PetHealthHistory[];
      } else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list'])) {
          dataArray = resRecord['list'] as PetHealthHistory[];
        } else if (resRecord['records'] && Array.isArray(resRecord['records'])) {
          dataArray = resRecord['records'] as PetHealthHistory[];
        }
      }

      if (dataArray && dataArray.length > 0) {
        this.healthHistoryList = dataArray;
        this.updateCharts(dataArray);
      } else {
        this.loadMockHistory();
      }
    }).catch(() => {
      this.loadMockHistory();
    }).finally(() => {
      this.isLoading = false;
    });
  }


  private loadMockHistory() {
    this.healthHistoryList = [
      { recordDate: "2024-02-28", bodyWeight: "4.5", bodyTemperature: "38.5", appetiteLevel: "Excellent", vaccinationStatus: "Up-to-date", dewormingStatus: "Completed" },
      { recordDate: "2024-01-15", bodyWeight: "4.4", bodyTemperature: "38.6", appetiteLevel: "Normal", vaccinationStatus: "Up-to-date", dewormingStatus: "Completed" },
      { recordDate: "2023-12-01", bodyWeight: "4.2", bodyTemperature: "38.4", appetiteLevel: "Normal", vaccinationStatus: "Up-to-date", dewormingStatus: "Pending" }
    ];
    this.updateCharts(this.healthHistoryList);
  }

  private updateCharts(data: PetHealthHistory[]) {

    const chartData = [...data].reverse();
    const dates = chartData.map(item => item.recordDate ? item.recordDate.substring(5, 10) : '');
    const temps = chartData.map(item => this.extractNumber(item.bodyTemperature));
    const weights = chartData.map(item => this.extractNumber(item.bodyWeight));

    this.lineOption.setVal({
      xAxis: { data: dates },
      series: [
        { name: '体温', data: temps },
        { name: '体重', data: weights }
      ]
    });


    let excellent = 0, normal = 0, poor = 0;
    data.forEach(item => {
      if (item.appetiteLevel === 'Excellent') excellent++;
      else if (item.appetiteLevel === 'Poor') poor++;
      else normal++;
    });


    const pieData: PieChartData[] = [];
    if (excellent > 0) pieData.push(new PieChartData(excellent, '食欲极佳'));
    if (normal > 0) pieData.push(new PieChartData(normal, '食欲正常'));
    if (poor > 0) pieData.push(new PieChartData(poor, '食欲不佳'));

    if (pieData.length > 0) {
      this.pieOption.setVal({ series: [{ data: pieData }] });
    }
  }

  build() {
    Scroll() {
      GridRow({
        breakpoints: { value: ["600vp", "840vp"], reference: BreakpointsReference.WindowSize },
        columns: { sm: 4, md: 8, lg: 12 },
        gutter: { x: 16, y: 16 }
      }) {
        GridCol({ span: { sm: 4, md: 4, lg: 4 } }) {
          Column({ space: 16 }) {
            this.HealthOverviewCard()
            this.MedicalStatusCard()
            this.AppetitePieChartCard()
          }
        }

        GridCol({ span: { sm: 4, md: 4, lg: 8 } }) {
          Column({ space: 16 }) {
            this.TrendLineChartCard()
            this.HistoryListCard()
          }
        }
      }
      .onBreakpointChange((breakpoint: string) => {
        this.currentBreakpoint = breakpoint;
      })
      .width('100%')
      .padding({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  @Builder
  private HealthOverviewCard() {
    Row() {
      Column({ space: 6 }) {
        Text(this.petInfo ? `${this.petInfo.petName} 的健康档案` : "宠物健康档案")
          .fontSize(14)
          .fontColor('#666666')
          .fontWeight(FontWeight.Medium)

        Row({ space: 8 }) {
          Text(this.petInfo?.currentWeight ? `${this.petInfo.currentWeight}kg` : '--')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Text("当前体重")
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ top: 10 })
        }

        Text(this.petInfo?.healthStatus === '健康' ? "🐾 整体状态非常棒，继续保持！" : "⚠️ 需要多加关注毛孩子的状态哦~")
          .fontSize(12)
          .fontColor('#888888')
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.heart_fill'))
        .fontSize(50)
        .fontColor(this.petInfo?.healthStatus === '健康' ? ['#FF4D4F'] : ['#FFA500'])
    }
    .rowGlassCardStyle()
  }

  @Builder
  private MedicalStatusCard() {
    Row() {

      Column({ space: 8 }) {

        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(28)
          .fontColor(this.getLatestHistory()?.vaccinationStatus === 'Up-to-date' ? ['#52C41A'] : ['#FF4D4F'])
        Text("疫苗状态")
          .fontSize(12)
          .fontColor('#666666')
        Text(this.getLatestHistory()?.vaccinationStatus === 'Up-to-date' ? "已接种" : "待接种")
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(40).color('#E5E5E5')


      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.star_circle_fill'))
          .fontSize(28)
          .fontColor(this.getLatestHistory()?.dewormingStatus === 'Completed' ? ['#1890FF'] : ['#FFA500'])
        Text("驱虫状态")
          .fontSize(12)
          .fontColor('#666666')
        Text(this.getLatestHistory()?.dewormingStatus === 'Completed' ? "已完成" : "待驱虫")
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .rowGlassCardStyle()
  }

  @Builder
  private AppetitePieChartCard() {
    Column() {
      Text("近期食欲分析")
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .margin({ bottom: 10 })

      McPieChart({
        options: this.pieOption
      })
        .width('100%')
        .height(180)
    }
    .colGlassCardStyle()
  }

  @Builder
  private TrendLineChartCard() {
    Column() {
      Text("体温与体重趋势")
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .margin({ bottom: 15 })

      McLineChart({
        options: this.lineOption
      })
        .width('100%')
        .height(220)
    }
    .colGlassCardStyle()
  }

  @Builder
  private HistoryListCard() {
    Column({ space: 12 }) {
      Text("近期健康记录")
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')

      if (this.isLoading) {
        LoadingProgress().width(30).height(30).margin(20).color('#FFB11B')
      } else if (this.healthHistoryList.length === 0) {
        Text("暂无健康记录")
          .fontSize(14)
          .fontColor('#888888')
          .margin({ top: 20, bottom: 20 })
      } else {
        ForEach(this.healthHistoryList, (item: PetHealthHistory, index: number) => {
          this.HistoryItemCard(item)
          if (index !== this.healthHistoryList.length - 1) {
            Divider().color('#E5E5E5').margin({ top: 4, bottom: 4 })
          }
        })
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private HistoryItemCard(item: PetHealthHistory) {
    Row() {
      Column({ space: 4 }) {
        Text(item.recordDate ? item.recordDate.substring(0, 10) : '未知日期')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)

        Text(`食欲: ${this.translateAppetite(item.appetiteLevel)} | 体温: ${item.bodyTemperature || '--'}℃`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(`${item.bodyWeight || '--'} kg`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1890FF')
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  private getLatestHistory(): PetHealthHistory | null {
    if (this.healthHistoryList.length > 0) return this.healthHistoryList[0];
    return null;
  }

  private translateAppetite(level: string | undefined): string {
    if (level === 'Excellent') return '极佳';
    if (level === 'Poor') return '不佳';
    return '正常';
  }
}

@Extend(Column) function colGlassCardStyle() {
  .width('100%').padding(20)
  .backgroundColor('rgba(255, 255, 255, 0.55)')
  .backgroundBlurStyle(BlurStyle.Thin)
  .borderRadius(20)
  .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)' })
  .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 6 })
}

@Extend(Row) function rowGlassCardStyle() {
  .width('100%').padding(20)
  .backgroundColor('rgba(255, 255, 255, 0.55)')
  .backgroundBlurStyle(BlurStyle.Thin)
  .borderRadius(20)
  .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)' })
  .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 6 })
}