import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { getMonitoring, getPets, putFeeding, getFeedingRecord } from '../api/services';
import { McLineChart, Options } from '@mcui/mccharts';
import {
  MonitoringBean,
  PetBean,
  UserBean,
  GetMonitoringRequest,
  PutFeedingRequest,
  GetFeedingRecordRequest,
  FeedingRecordBean
} from '../api/types';

@Component
export struct Dashboard {

  @State currentBreakpoint: string = 'sm';
  @State userKey: string = '';

  @State envData: MonitoringBean | null = null;
  @State petList: PetBean[] = [];
  @State feedRecordList: FeedingRecordBean[] = [];
  @State isFeeding: boolean = false;


  @State isLoadingEnv: boolean = true;
  @State isEnvError: boolean = false;


  @State lineOption: Options = new Options({
    xAxis: {
      data: ['08:00', '12:00', '16:00', '20:00', '24:00']
    },
    yAxis: [
      { name: '温度' },
      { name: '湿度' }
    ],
    series: [
      {
        name: '温度',
        type: 'line',
        data: [22, 24, 26, 23, 21]
      },
      {
        name: '湿度',
        type: 'line',
        yAxisIndex: 1,
        data: [40, 45, 50, 48, 42]
      }
    ]
  });

  aboutToAppear() {
    this.initData();
  }


  private extractNumber(str: string | undefined): number {
    if (!str) return 0;
    const match = str.match(/-?\d+(\.\d+)?/);
    return match ? Number(match[0]) : 0;
  }

  private initData() {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userKey = userInfo.key || "";
      }
    } catch (e) {
      const errorObj = e as Error;
      LogUtil.error("[Dashboard] 解析本地用户信息失败: " + errorObj.message);
    }

    if (!this.userKey || this.userKey === "") {
      ToastUtil.showToast("身份验证失败，请重新登录");
      this.isEnvError = true;
      this.isLoadingEnv = false;
      return;
    }

    const now = new Date();
    const pastTimeEnv = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const pastTimeFeed = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const formatTime = (d: Date) => {
      const pad = (n: number) => n.toString().padStart(2, '0');
      return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
    };


    this.isLoadingEnv = true;
    this.isEnvError = false;

    const envParams: GetMonitoringRequest = {
      key: this.userKey,
      userId: "1",
      page: "1",
      size: "15",
      startTime: formatTime(pastTimeEnv),
      endTime: formatTime(now)
    };

    getMonitoring(envParams).then((res: Object) => {
      let dataArray: MonitoringBean[] = [];
      if (Array.isArray(res)) {
        dataArray = res as MonitoringBean[];
      } else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list'])) {
          dataArray = resRecord['list'] as MonitoringBean[];
        } else if (resRecord['records'] && Array.isArray(resRecord['records'])) {
          dataArray = resRecord['records'] as MonitoringBean[];
        }
      }

      if (dataArray && dataArray.length > 0) {
        this.envData = dataArray[0];
        this.isEnvError = false;


        const chartData = [...dataArray].reverse();
        const times = chartData.map(item => item.monitoringTime ? item.monitoringTime.substring(11, 16) : '');
        const temps = chartData.map(item => this.extractNumber(item.temperature));
        const humis = chartData.map(item => this.extractNumber(item.humidity));

        this.lineOption.setVal({
          xAxis: { data: times },
          series: [
            { name: '温度', data: temps },
            { name: '湿度', data: humis }
          ]
        });
      } else {
        this.isEnvError = false;
        this.envData = {
          userId: "1",
          monitoringTime: formatTime(now),
          temperature: "26.5",
          humidity: "45",
          pm25: "12",
          co2: "400",
          tvoc: "0.1",
          noiseLevel: "35",
          lightIntensity: "300",
          airQuality: "Good"
        } as MonitoringBean;
      }
    }).catch((err: Object) => {
      this.isEnvError = true;
      this.envData = {
        userId: "1",
        monitoringTime: "2026-02-28",
        temperature: "--",
        humidity: "--",
        pm25: "--",
        co2: "--",
        tvoc: "--",
        noiseLevel: "--",
        lightIntensity: "--",
        airQuality: "Poor"
      } as MonitoringBean;
    }).finally(() => {
      this.isLoadingEnv = false;
    });


    getPets(this.userKey).then((res: Object) => {
      if (Array.isArray(res) && res.length > 0) {
        this.petList = res as PetBean[];
      } else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list']) && resRecord['list'].length > 0) {
          this.petList = resRecord['list'] as PetBean[];
        } else {
          throw new Error("宠物列表为空");
        }
      }
    }).catch((err: Object) => {
      this.petList = [
        {
          id: 1,
          userId: 1,
          petName: "布丁",
          petSpecies: "猫",
          petBreed: "英短",
          petGender: "female",
          birthDate: "2023-01-01",
          currentWeight: 4.5,
          healthStatus: "健康",
          createdAt: "",
          updatedAt: ""
        } as PetBean
      ];
    });


    const feedRecordParams: GetFeedingRecordRequest = {
      key: this.userKey,
      petId: "1",
      startTime: formatTime(pastTimeFeed),
      endTime: formatTime(now),
      page: "1",
      size: "50"
    };

    getFeedingRecord(feedRecordParams).then((res: Object) => {
      let dataArray: FeedingRecordBean[] = [];
      if (Array.isArray(res)) {
        dataArray = res as FeedingRecordBean[];
      } else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list'])) {
          dataArray = resRecord['list'] as FeedingRecordBean[];
        } else if (resRecord['records'] && Array.isArray(resRecord['records'])) {
          dataArray = resRecord['records'] as FeedingRecordBean[];
        }
      }
      this.feedRecordList = dataArray;
    }).catch((err: Object) => {
      this.feedRecordList = [];
    });
  }


  private async handleQuickFeed() {
    if (!this.userKey) {
      ToastUtil.showToast("身份验证失效，无法投喂");
      return;
    }
    if (this.petList.length === 0) {
      ToastUtil.showToast("未获取到宠物信息，无法投喂");
      return;
    }
    if (this.isFeeding) return;

    this.isFeeding = true;
    try {
      const feedParams: PutFeedingRequest = {
        key: this.userKey,
        petId: this.petList[0]?.id?.toString() || "1",
        plannedAmount: "150",
        deviceId: "1"
      };

      await putFeeding(feedParams);
      ToastUtil.showToast("🍗 投喂指令已发送，数据同步可能会有5分钟延迟！");
      this.feedRecordList.push({} as FeedingRecordBean);
    } catch (err) {
      ToastUtil.showToast("🍗 投喂失败，请稍后再试");
    } finally {
      this.isFeeding = false;
    }
  }


  private getWeatherStatus(): string {
    if (!this.envData || !this.envData.temperature) return "未知";
    const temp = this.extractNumber(this.envData.temperature);
    if (temp >= 30) return "炎热";
    if (temp <= 10) return "寒冷";
    return "舒适";
  }


  private getOutdoorAdvice(): string {
    if (!this.envData) return "暂无数据，请稍后查看~";

    const temp = this.extractNumber(this.envData.temperature);
    const isBadAir = this.envData.airQuality === 'Poor';

    if (isBadAir) {
      return "当前空气质量较差，建议让毛孩子宅家玩耍哦~";
    }
    if (temp >= 30) {
      return "气温较高，注意防暑降温，避免地面烫伤脚垫！";
    }
    if (temp <= 10) {
      return "气温偏低，出门记得给怕冷的毛孩子穿上衣服~";
    }

    return "温度适宜，空气质量优，非常适合带毛孩子出门散步！";
  }


  private getWeatherIcon(): string {
    if (!this.envData || !this.envData.temperature) return 'sys.symbol.cloud';
    const temp = this.extractNumber(this.envData.temperature);
    if (temp >= 30) return 'sys.symbol.sun_max_fill';
    if (temp <= 10) return 'sys.symbol.wind';
    return 'sys.symbol.sun_max_fill';
  }


  private getWeatherIconColor(): string {
    if (!this.envData || !this.envData.temperature) return '#CCCCCC';
    const temp = this.extractNumber(this.envData.temperature);
    if (temp >= 30) return '#FF4D4F';
    if (temp <= 10) return '#1890FF';
    return '#FFA500';
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
            this.WeatherCard()
            this.FeedSummaryCard()
            this.QuickFeedCard()
          }
        }


        GridCol({ span: { sm: 4, md: 4, lg: 8 } }) {
          Column({ space: 16 }) {
            this.EnvironmentCard()

            if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
              this.AdvancedChartsCard()
            }
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
  private WeatherCard() {
    Row() {
      Column({ space: 6 }) {
        Text("当前环境与出行建议")
          .fontSize(14)
          .fontColor('#666666')
          .fontWeight(FontWeight.Medium)

        Row({ space: 8 }) {
          Text(this.envData?.temperature ? `${this.extractNumber(this.envData.temperature)}°C` : '--')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)

          Text(this.getWeatherStatus())
            .fontSize(16)
            .fontColor(Color.Black)
            .margin({ top: 10 })
        }

        Text(this.getOutdoorAdvice())
          .fontSize(12)
          .fontColor('#888888')
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r(this.getWeatherIcon()))
        .fontSize(50)
        .fontColor([this.getWeatherIconColor()])
    }
    .rowGlassCardStyle()
  }




  @Builder
  private FeedSummaryCard() {
    Row() {
      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.bag'))
          .fontSize(28)
          .fontColor(['#FFB11B'])
        Text("今日喂食")
          .fontSize(12)
          .fontColor('#666666')
        Text(`${this.feedRecordList.length} 次`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(50).color('#E5E5E5')

      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.heart_fill'))
          .fontSize(28)
          .fontColor(['#FF4D4F'])
        Text("健康状态")
          .fontSize(12)
          .fontColor('#666666')
        Text(this.petList.length > 0 ? (this.petList[0].healthStatus || '良好') : '--')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .rowGlassCardStyle()
  }




  @Builder
  private QuickFeedCard() {
    Row() {
      Column({ space: 4 }) {
        Text("快捷设备").fontSize(14).fontColor('#666666').fontWeight(FontWeight.Medium)
        Text(this.petList.length > 0 ? `给 ${this.petList[0].petName} 加餐` : "智能喂食器")
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(this.isFeeding ? "投喂中" : "一键开饭")
        .height(45)
        .backgroundColor(this.isFeeding ? 'rgba(255, 165, 0, 0.5)' : '#FFB11B')
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .borderRadius(22)
        .enabled(!this.isFeeding)
        .onClick(() => { this.handleQuickFeed(); })
    }
    .rowGlassCardStyle()
  }




  @Builder
  private EnvironmentCard() {
    Column({ space: 20 }) {
      Row() {
        Text("室内环境监测").fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        Blank()

        if (this.isEnvError) {
          Text('设备离线')
            .fontSize(12).fontColor('#FF4D4F')
            .backgroundColor('rgba(255, 77, 79, 0.1)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(12)
        } else {
          Text('设备在线')
            .fontSize(12).fontColor('#52C41A')
            .backgroundColor('rgba(82, 196, 26, 0.1)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(12)
        }
      }
      .width('100%')

      if (this.isLoadingEnv) {
        LoadingProgress().width(30).height(30).margin(20).color('#FFB11B')
      } else if (this.envData) {
        GridRow({ columns: 4, gutter: 10 }) {
          GridCol({ span: 1 }) { this.EnvSimpleItem('sys.symbol.thermometer', '温度', this.envData.temperature, '#FF4D4F') }
          GridCol({ span: 1 }) { this.EnvSimpleItem('sys.symbol.drop', '湿度', this.envData.humidity, '#1890FF') }

          GridCol({ span: 1 }) { this.EnvSimpleItem('sys.symbol.leaf_fill', 'PM2.5', this.envData.pm25, '#52C41A') }
          GridCol({ span: 1 }) { this.EnvSimpleItem('sys.symbol.waveform', '噪音', this.envData.noiseLevel, '#722ED1') }
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private EnvSimpleItem(icon: string, title: string, value: string | undefined, iconColor: string) {
    Column({ space: 8 }) {
      SymbolGlyph($r(icon))
        .fontSize(24)
        .fontColor([iconColor])

      Text(title)
        .fontSize(12)
        .fontColor('#888888')

      Text(value || '--')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private AdvancedChartsCard() {
    Column() {
      Text("温湿度历史趋势")
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