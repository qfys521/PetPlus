import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import { getPets, updatePets, getFeedingSchedules, addFeedingDevices, putFeeding } from '../api/services';
import {
  PetBean,
  UserBean,
  FeedingSchedulesBean,
  UpdatePetsRequest,
  AddFeedingDeviceRequest,
  PutFeedingRequest
} from '../api/types';

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

@Component
export struct Archival {
  @State currentBreakpoint: string = 'sm';
  @State userKey: string = '';

  @State petList: PetBean[] = [];
  @State selectedPetId: number | null = null;
  @State isLoadingPets: boolean = true;

  @State scheduleList: FeedingSchedulesBean[] = [];
  @State isLoadingSchedules: boolean = false;

  @State petAvatarMap: Record<number, string> = {};

  private petDialogController: CustomDialogController = new CustomDialogController({
    builder: PetDialog({
      onConfirm: (data: PetBean): void => this.handleSavePet(data)
    }),
    alignment: DialogAlignment.Center
  });

  private scheduleDialogController: CustomDialogController = new CustomDialogController({
    builder: ScheduleDialog({
      onConfirm: (data: AddFeedingDeviceRequest): void => this.handleSaveSchedule(data)
    }),
    alignment: DialogAlignment.Center
  });

  private feedDialogController: CustomDialogController = new CustomDialogController({
    builder: InstantFeedDialog({
      onConfirm: (amount: string): void => this.handleInstantFeed(amount)
    }),
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.initData();
  }

  private initData(): void {
    try {
      const userInfoStr = PreferencesUtil.getStringSync("user_info", "");
      if (userInfoStr) {
        const userInfo: UserBean = JSON.parse(userInfoStr);
        this.userKey = userInfo.key || "";
      }
    } catch (e) {
      LogUtil.error("[Archival] 解析用户信息失败");
    }

    if (!this.userKey) {
      ToastUtil.showToast("请先登录");
      return;
    }

    const avatarStr = PreferencesUtil.getStringSync("pet_avatars", "{}");
    if (avatarStr) {
      try {
        this.petAvatarMap = JSON.parse(avatarStr);
      } catch (e) {
        this.petAvatarMap = {};
      }
    }

    this.loadPets();
  }

  private loadPets(): void {
    this.isLoadingPets = true;
    getPets(this.userKey).then((res: Object) => {
      let dataArray: PetBean[] = [];
      if (Array.isArray(res)) dataArray = res as PetBean[];
      else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list'])) dataArray = resRecord['list'] as PetBean[];
      }

      this.petList = dataArray;
      if (this.petList.length > 0) {
        const exists = this.petList.some(p => p.id === this.selectedPetId);
        if (this.selectedPetId === null || !exists) {
          this.selectedPetId = this.petList[0].id;
          this.loadSchedules(this.selectedPetId.toString());
        }
      } else {
        this.selectedPetId = null;
        this.scheduleList = [];
      }
    }).catch(() => {
      ToastUtil.showToast("获取云端宠物数据失败");
      this.petList = [];
    }).finally(() => {
      this.isLoadingPets = false;
    });
  }

  private loadSchedules(petId: string): void {
    this.isLoadingSchedules = true;
    getFeedingSchedules(this.userKey, petId).then((res: Object) => {
      let dataArray: FeedingSchedulesBean[] = [];
      if (Array.isArray(res)) dataArray = res as FeedingSchedulesBean[];
      this.scheduleList = dataArray;
    }).catch(() => {
      this.scheduleList = [];
    }).finally(() => {
      this.isLoadingSchedules = false;
    });
  }

  private handleSavePet(petData: PetBean): void {
    const params: UpdatePetsRequest = {
      key: this.userKey,
      petName: petData.petName || "未命名",
      petSpecies: petData.petSpecies || "猫",
      petBreed: petData.petBreed || "未知",
      petGender: petData.petGender || "male",
      birthDate: petData.birthDate || "2023-01-01",
      currentweight: petData.currentWeight?.toString() || "0",
      healthstatus: petData.healthStatus || "健康",
      id: petData.id === -1 ? "" : petData.id.toString(),
      userId: "1"
    };

    updatePets(params).then(() => {
      ToastUtil.showToast("宠物信息保存成功");
      this.loadPets();
    }).catch((): void => ToastUtil.showToast("宠物信息保存失败"));
  }

  private handleDeletePet(id: number): void {
    ToastUtil.showToast("正在请求云端删除...");
    this.petList = this.petList.filter(p => p.id !== id);
    if (this.selectedPetId === id) this.selectedPetId = null;
  }

  private handleSaveSchedule(data: AddFeedingDeviceRequest): void {
    data.key = this.userKey;
    data.petId = this.selectedPetId?.toString() || "1";
    data.deviceId = "1";

    addFeedingDevices(data).then(() => {
      ToastUtil.showToast("喂食计划添加成功");
      this.loadSchedules(data.petId);
    }).catch((): void => ToastUtil.showToast("计划添加失败"));
  }

  private handleDeleteSchedule(id: string): void {
    ToastUtil.showToast("正在请求云端删除...");
    this.scheduleList = this.scheduleList.filter(s => s.id !== id);
  }

  private handleInstantFeed(amount: string): void {
    if (!this.selectedPetId) {
      ToastUtil.showToast("请先选择宠物");
      return;
    }
    const req: PutFeedingRequest = {
      key: this.userKey,
      petId: this.selectedPetId.toString(),
      deviceId: "1",
      plannedAmount: amount
    };
    putFeeding(req).then(() => {
      ToastUtil.showToast(`已定量投喂 ${amount}g，设备即将出粮`);
    }).catch((): void => ToastUtil.showToast("投喂指令发送失败"));
  }

  private async selectAndSaveAvatar(petId: number): Promise<void> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const sourceUri = photoSelectResult.photoUris[0];

        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const fileName = `pet_avatar_${petId}_${new Date().getTime()}.jpg`;
        const destPath = context.filesDir + '/' + fileName;

        const fileSource = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
        const fileDest = await fileIo.open(destPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

        await fileIo.copyFile(fileSource.fd, fileDest.fd);
        await fileIo.close(fileSource.fd);
        await fileIo.close(fileDest.fd);

        const safeUri = 'file://' + destPath;
        this.petAvatarMap[petId] = safeUri;

        PreferencesUtil.putSync("pet_avatars", JSON.stringify(this.petAvatarMap));
        ToastUtil.showToast("头像更新成功");
      }
    } catch (err) {
      LogUtil.error("选择或保存图片失败: " + JSON.stringify(err));
      ToastUtil.showToast("设置头像取消或失败");
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.bg2'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .backdropBlur(30)

      Scroll() {
        GridRow({
          breakpoints: { value: ["600vp", "840vp"], reference: BreakpointsReference.WindowSize },
          columns: { sm: 4, md: 8, lg: 12 },
          gutter: { x: 16, y: 16 }
        }) {
          GridCol({ span: { sm: 4, md: 4, lg: 5 } }) {
            this.PetSection()
          }

          GridCol({ span: { sm: 4, md: 4, lg: 7 } }) {
            if (this.selectedPetId !== null) {
              this.DeviceSection()
            } else {
              this.EmptyDeviceSection()
            }
          }
        }
        .onBreakpointChange((bp: string): void => { this.currentBreakpoint = bp })
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private PetSection(): void {
    Column({ space: 16 }) {
      Row() {
        Text("🐾 宠物档案管理")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
        Blank()
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(20)
            .fontColor([Color.White])
        }
        .width(36).height(36)
        .backgroundColor('#1890FF')
        .onClick(() => { this.petDialogController.open() })
      }
      .width('100%')

      if (this.isLoadingPets) {
        LoadingProgress().width(40).height(40).alignSelf(ItemAlign.Center)
      } else if (this.petList.length === 0) {
        Text("暂无宠物档案，请点击右上角添加").fontColor('#888').margin({ top: 20 })
      } else {
        ForEach(this.petList, (pet: PetBean) => {
          this.PetCard(pet)
        })
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private PetCard(pet: PetBean): void {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          if (this.petAvatarMap[pet.id]) {
            Image(this.petAvatarMap[pet.id]).width(50).height(50).borderRadius(25).blur(5)
            Image(this.petAvatarMap[pet.id]).width(46).height(46).borderRadius(23).objectFit(ImageFit.Cover)
          } else {
            Circle({ width: 50, height: 50 }).fill('#E5E5E5')
            SymbolGlyph($r('sys.symbol.camera')).fontSize(20).fontColor(['#999'])
          }
        }
        .margin({ right: 12 })
        .onClick(() => { this.selectAndSaveAvatar(pet.id); })

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(pet.petName).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
            Text(pet.petGender === 'male' ? '♂' : '♀').fontColor(pet.petGender === 'male' ? '#1890FF' : '#FF4D4F')
          }
          Text(`${pet.petBreed} | ${pet.currentWeight}kg`).fontSize(13).fontColor('#666')

          if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md') {
            Text(`健康状态: ${pet.healthStatus}`).fontSize(12).fontColor('#52C41A').margin({ top: 4 })
            Text(`档案更新: ${pet.updatedAt ? pet.updatedAt.substring(0, 10) : '未知'}`).fontSize(12).fontColor('#999')
            Text(`云端ID: ${pet.id}`).fontSize(10).fontColor('#CCC')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 10 }) {
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.AI_pencil'))
              .fontSize(18)
              .fontColor([Color.White])
          }
          .width(32).height(32)
          .backgroundColor('#FFB11B')
          .onClick(() => { this.petDialogController.open(); })
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedPetId === pet.id ? 'rgba(24, 144, 255, 0.15)' : 'rgba(255, 255, 255, 0.4)')
    .border({ width: this.selectedPetId === pet.id ? 2 : 0, color: '#1890FF', radius: 16 })
    .borderRadius(16)
    .margin({ bottom: 10 })
    .onClick(() => {
      this.selectedPetId = pet.id;
      this.loadSchedules(pet.id.toString());
    })
  }

  @Builder
  private DeviceSection(): void {
    Column({ space: 16 }) {
      Row() {
        Text("⚙️ 投喂计划与设备")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
        Blank()

        Row({ space: 12 }) {
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.bolt'))
              .fontSize(20)
              .fontColor([Color.White])
          }
          .width(36).height(36)
          .backgroundColor('#FFB11B')
          .onClick(() => { this.feedDialogController.open() })

          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(20)
              .fontColor([Color.White])
          }
          .width(36).height(36)
          .backgroundColor('#52C41A')
          .onClick(() => { this.scheduleDialogController.open() })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.isLoadingSchedules) {
        LoadingProgress().width(40).height(40).alignSelf(ItemAlign.Center)
      } else if (this.scheduleList.length === 0) {
        Text("该宠物云端暂无喂食计划").fontColor('#888').margin({ top: 20 })
      } else {
        ForEach(this.scheduleList, (item: FeedingSchedulesBean) => {
          this.ScheduleCard(item)
        })
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private EmptyDeviceSection(): void {
    Column() {
      Text("请在左侧选择一个宠物档案以查看其云端设备").fontColor('#888').margin({ top: 40 })
    }
    .colGlassCardStyle()
    .justifyContent(FlexAlign.Center)
    .height(300)
  }

  @Builder
  private ScheduleCard(schedule: FeedingSchedulesBean): void {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.clock')).fontSize(18).fontColor(['#1890FF'])
          Text(schedule.scheduleTime).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        }
        Text(`投喂量: ${schedule.foodAmount}g`).fontSize(14).fontColor('#666')

        if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md') {
          Text(`绑定设备: ${schedule.deviceName || '云端智能喂食器'}`).fontSize(12).fontColor('#888')
          Text(`计划ID: ${schedule.id}`).fontSize(10).fontColor('#CCC')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)


      Column({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: String(schedule.isActive) === 'true' })
          .onChange((isOn: boolean): void => {
            ToastUtil.showToast(`计划已${isOn ? '开启' : '关闭'}`);
          })
        Button("删除")
          .height(28)
          .fontSize(12)
          .backgroundColor('transparent')
          .fontColor('#FF4D4F')
          .border({ width: 1, color: '#FF4D4F', radius: 14 })
          .onClick(() => { this.handleDeleteSchedule(schedule.id) })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('rgba(255, 255, 255, 0.4)')
    .borderRadius(16)
    .margin({ bottom: 10 })
  }
}




@CustomDialog
struct PetDialog {
  controller: CustomDialogController
  onConfirm: (data: PetBean) => void = (data: PetBean): void => {}

  @State pName: string = ''
  @State pBreed: string = ''
  @State pWeight: string = ''

  build() {
    Column({ space: 16 }) {
      Text("新增宠物档案").fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ placeholder: "宠物昵称" }).onChange((v: string) => { this.pName = v })
      TextInput({ placeholder: "品种 (如: 英短/金毛)" }).onChange((v: string) => { this.pBreed = v })
      TextInput({ placeholder: "体重 (kg)" }).type(InputType.Number).onChange((v: string) => { this.pWeight = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1)
          .onClick(() => { this.controller.close() })
        Button("保存").backgroundColor('#1890FF').layoutWeight(1)
          .onClick(() => {
            if (!this.pName || !this.pWeight) {
              ToastUtil.showToast("名称和体重必填");
              return;
            }
            const petData: PetBean = {
              id: -1,
              userId: 1, petName: this.pName, petSpecies: "猫/狗", petBreed: this.pBreed,
              petGender: "male", birthDate: "2023-01-01", currentWeight: Number(this.pWeight),
              healthStatus: "健康", createdAt: "", updatedAt: ""
            };
            this.onConfirm(petData);
            this.controller.close();
          })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}




@CustomDialog
struct ScheduleDialog {
  controller: CustomDialogController
  onConfirm: (data: AddFeedingDeviceRequest) => void = (data: AddFeedingDeviceRequest): void => {}

  @State sTime: string = '08:00:00'
  @State sAmount: string = '50'
  @State sNote: string = '早饭'

  build() {
    Column({ space: 16 }) {
      Text("云端喂食计划").fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ text: this.sTime, placeholder: "时间 (HH:mm:ss)" }).onChange((v: string) => { this.sTime = v })
      TextInput({ text: this.sAmount, placeholder: "投喂量 (g)" }).type(InputType.Number).onChange((v: string) => { this.sAmount = v })
      TextInput({ text: this.sNote, placeholder: "备注" }).onChange((v: string) => { this.sNote = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1)
          .onClick(() => { this.controller.close() })
        Button("保存").backgroundColor('#52C41A').layoutWeight(1)
          .onClick(() => {
            if (!this.sTime || !this.sAmount) {
              ToastUtil.showToast("时间与投喂量必填");
              return;
            }
            const data: AddFeedingDeviceRequest = {
              key: "", petId: "", deviceId: "1",
              scheduleTime: this.sTime, foodAmount: this.sAmount, isActive: "true", schedulesInfo: this.sNote
            };
            this.onConfirm(data);
            this.controller.close();
          })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}




@CustomDialog
struct InstantFeedDialog {
  controller: CustomDialogController
  onConfirm: (amount: string) => void = (amount: string): void => {}

  @State amount: string = '100'

  build() {
    Column({ space: 16 }) {
      Text("⚡ 立即定量投喂").fontSize(20).fontWeight(FontWeight.Bold)
      Text("云端设备将立即释放设定量的食物").fontSize(13).fontColor('#888')

      TextInput({ text: this.amount, placeholder: "克数 (g)" }).type(InputType.Number).onChange((v: string) => { this.amount = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1)
          .onClick(() => { this.controller.close() })
        Button("出粮").backgroundColor('#FFB11B').layoutWeight(1)
          .onClick(() => {
            if (!this.amount) {
              ToastUtil.showToast("请输入投喂量");
              return;
            }
            this.onConfirm(this.amount);
            this.controller.close();
          })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}


@Extend(Column) function colGlassCardStyle() {
  .width('100%').padding(20)
  .backgroundColor('rgba(255, 255, 255, 0.45)')
  .borderRadius(20)
  .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)' })
  .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 6 })
}

@Extend(Row) function rowGlassCardStyle() {
  .width('100%').padding(20)
  .backgroundColor('rgba(255, 255, 255, 0.45)')
  .borderRadius(20)
  .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)' })
  .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 6 })
}