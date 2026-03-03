import { LogUtil, PreferencesUtil, ToastUtil } from '@pura/harmony-utils';
import {
  getPets,
  addPets,
  updatePets,
  delPets,
  getFeedingSchedules,
  addFeedingSchedules,
  updateFeedingSchedules,
  delFeedingSchedules,
  putFeeding,
  getFeedingDevices,
  addFeedingDevices,
  updateFeedingDevices,
  delFeedingDevices
} from '../api/services';
import {
  PetBean,
  UserBean,
  FeedingSchedulesBean,
  UpdatePetsRequest,
  DelPetsRequest,
  AddFeedingSchedulesRequest,
  UpdateFeedingSchedulesRequest,
  DelFeedingSchedulesRequest,
  PutFeedingRequest,
  AddFeedingDevicesRequest,
  UpdateFeedingDevicesRequest,
  DelFeedingDevicesRequest
} from '../api/types';

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

export interface DeviceBean {
  id: string;
  userId?: string;
  deviceName: string;
  deviceType: string;
  deviceStatus?: string;
  installLocation: string;
}

@Component
export struct Archival {
  @State currentBreakpoint: string = 'sm';
  @State userKey: string = '';
  @State userId: string = '1';

  // --- 模块折叠状态（默认折叠） ---
  @State isPetExpanded: boolean = false;
  @State isDeviceExpanded: boolean = false;
  @State isScheduleExpanded: boolean = false;

  @State petList: PetBean[] = [];
  @State selectedPetId: number | null = null;
  @State isLoadingPets: boolean = true;

  @State scheduleList: FeedingSchedulesBean[] = [];
  @State isLoadingSchedules: boolean = false;

  @State deviceList: DeviceBean[] = [];
  @State isLoadingDevices: boolean = false;

  @State petAvatarMap: Record<number, string> = {};

  // --- 计划弹窗状态 ---
  @State sTime: string = '08:00:00';
  @State sAmount: string = '50';
  @State sNote: string = '常规投喂';
  @State sEditId: string = '';
  @State sIsActive: string = '1';
  @State sDeviceId: string = '';

  // --- 手动投喂弹窗状态 ---
  @State fDeviceId: string = '';

  // --- 设备弹窗状态 ---
  @State dName: string = '';
  @State dType: string = '';
  @State dLoc: string = '';
  @State dEditId: string = '';

  private petDialogController: CustomDialogController = new CustomDialogController({
    builder: PetDialog({
      onConfirm: (data: PetBean): void => this.handleSavePet(data)
    }),
    alignment: DialogAlignment.Center
  });

  private scheduleDialogController: CustomDialogController = new CustomDialogController({
    builder: ScheduleDialog({
      deviceList: $deviceList,
      sDeviceId: $sDeviceId,
      sTime: $sTime,
      sAmount: $sAmount,
      sNote: $sNote,
      sEditId: $sEditId,
      onConfirm: (): void => this.handleSaveSchedule()
    }),
    alignment: DialogAlignment.Center
  });

  private feedDialogController: CustomDialogController = new CustomDialogController({
    builder: InstantFeedDialog({
      deviceList: $deviceList,
      fDeviceId: $fDeviceId,
      onConfirm: (amount: string): void => this.handleInstantFeed(amount)
    }),
    alignment: DialogAlignment.Center
  });

  private deviceDialogController: CustomDialogController = new CustomDialogController({
    builder: DeviceDialog({
      dName: $dName,
      dType: $dType,
      dLoc: $dLoc,
      dEditId: $dEditId,
      onConfirm: (): void => this.handleSaveDevice()
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
        this.userId = userInfo.id || "1";
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

    this.loadDevices();
    this.loadPets();
  }

  // ================= 逻辑方法 =================
  private loadPets(): void {
    this.isLoadingPets = true;
    getPets(this.userKey, this.userId).then((res: Object): void => {
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
    }).catch((): void => {
      this.petList = [];
    }).finally((): void => {
      this.isLoadingPets = false;
    });
  }

  private handleSavePet(petData: PetBean): void {
    const params: UpdatePetsRequest = {
      key: this.userKey, petName: petData.petName || "未命名",
      petSpecies: petData.petSpecies || "猫", petBreed: petData.petBreed || "未知",
      petGender: petData.petGender || "male", birthDate: petData.birthDate || "2023-01-01",
      currentWeight: petData.currentWeight?.toString() || "0", healthStatus: petData.healthStatus || "健康",
      id: petData.id === -1 ? "" : petData.id.toString(), userId: this.userId
    };

    if (petData.id === -1) {
      addPets(params).then((): void => { ToastUtil.showToast("宠物添加成功"); this.loadPets(); })
        .catch((): void => ToastUtil.showToast("宠物添加失败"));
    } else {
      updatePets(params).then((): void => { ToastUtil.showToast("宠物更新成功"); this.loadPets(); })
        .catch((): void => ToastUtil.showToast("宠物更新失败"));
    }
  }

  private handleDeletePet(id: number): void {
    const req: DelPetsRequest = { key: this.userKey, userId: this.userId, id: id.toString() };
    delPets(req)
      .then((): void => { ToastUtil.showToast("宠物删除成功"); this.loadPets(); })
      .catch((): void => ToastUtil.showToast("宠物删除失败"));
  }

  private loadSchedules(petId: string): void {
    this.isLoadingSchedules = true;
    getFeedingSchedules(this.userKey, petId).then((res: Object): void => {
      let dataArray: FeedingSchedulesBean[] = [];
      if (Array.isArray(res)) dataArray = res as FeedingSchedulesBean[];
      this.scheduleList = dataArray;
    }).catch((): void => { this.scheduleList = []; })
      .finally((): void => { this.isLoadingSchedules = false; });
  }

  private openScheduleDialog(editItem?: FeedingSchedulesBean): void {
    if (editItem) {
      this.sTime = editItem.scheduleTime; this.sAmount = editItem.foodAmount;
      this.sNote = editItem.petBreed || '常规投喂'; this.sEditId = editItem.id;
      this.sIsActive = (editItem.isActive === true || String(editItem.isActive) === 'true' || editItem.isActive === 1 || String(editItem.isActive) === '1') ? '1' : '0';
      this.sDeviceId = editItem.deviceId || (this.deviceList.length > 0 ? this.deviceList[0].id : '');
    } else {
      this.sTime = '08:00:00'; this.sAmount = '50'; this.sNote = '早饭';
      this.sEditId = ''; this.sIsActive = '1';
      this.sDeviceId = this.deviceList.length > 0 ? this.deviceList[0].id : '';
    }
    this.scheduleDialogController.open();
  }

  private handleSaveSchedule(): void {
    if (!this.sTime || !this.sAmount) { ToastUtil.showToast("必填项为空"); return; }
    if (!this.sDeviceId) { ToastUtil.showToast("请选择设备"); return; }

    if (this.sEditId) {
      const updateReq: UpdateFeedingSchedulesRequest = {
        key: this.userKey, userId: this.userId, petId: this.selectedPetId?.toString() || "1",
        deviceId: this.sDeviceId, scheduleTime: this.sTime, foodAmount: this.sAmount,
        isActive: this.sIsActive, schedulesInfo: this.sNote, id: this.sEditId
      };
      updateFeedingSchedules(updateReq).then((): void => { ToastUtil.showToast("修改成功"); if(this.selectedPetId) this.loadSchedules(this.selectedPetId.toString()); })
        .catch((): void => ToastUtil.showToast("修改失败"));
    } else {
      const addReq: AddFeedingSchedulesRequest = {
        key: this.userKey, petId: this.selectedPetId?.toString() || "1",
        deviceId: this.sDeviceId, scheduleTime: this.sTime, foodAmount: this.sAmount,
        isActive: this.sIsActive, schedulesInfo: this.sNote
      };
      addFeedingSchedules(addReq).then((): void => { ToastUtil.showToast("添加成功"); if(this.selectedPetId) this.loadSchedules(this.selectedPetId.toString()); })
        .catch((): void => ToastUtil.showToast("添加失败"));
    }
  }

  private handleDeleteSchedule(id: string): void {
    const req: DelFeedingSchedulesRequest = { key: this.userKey, userId: this.userId, id: id };
    delFeedingSchedules(req)
      .then((): void => { ToastUtil.showToast("删除成功"); if(this.selectedPetId) this.loadSchedules(this.selectedPetId.toString()); })
      .catch((): void => ToastUtil.showToast("删除失败"));
  }

  private handleInstantFeed(amount: string): void {
    if (!this.selectedPetId || !this.fDeviceId) return;
    const req: PutFeedingRequest = { key: this.userKey, petId: this.selectedPetId.toString(), deviceId: this.fDeviceId, plannedAmount: amount };
    putFeeding(req)
      .then((): void => { ToastUtil.showToast(`已下发指令投喂 ${amount}g`); })
      .catch((): void => ToastUtil.showToast("投喂失败"));
  }

  private loadDevices(): void {
    this.isLoadingDevices = true;
    getFeedingDevices(this.userKey, this.userId).then((res: Object): void => {
      let dataArray: DeviceBean[] = [];
      if (Array.isArray(res)) dataArray = res as DeviceBean[];
      else {
        const resRecord = res as Record<string, Object>;
        if (resRecord['list'] && Array.isArray(resRecord['list'])) dataArray = resRecord['list'] as DeviceBean[];
      }
      this.deviceList = dataArray;
    }).catch((): void => { this.deviceList = []; })
      .finally((): void => { this.isLoadingDevices = false; });
  }

  private openDeviceDialog(editItem?: DeviceBean): void {
    if (editItem) {
      this.dName = editItem.deviceName; this.dType = editItem.deviceType;
      this.dLoc = editItem.installLocation; this.dEditId = editItem.id;
    } else {
      this.dName = ''; this.dType = '自动喂食器'; this.dLoc = '客厅'; this.dEditId = '';
    }
    this.deviceDialogController.open();
  }

  private handleSaveDevice(): void {
    if (!this.dName || !this.dLoc) return;

    if (this.dEditId) {
      const updateReq: UpdateFeedingDevicesRequest = {
        key: this.userKey, userId: this.userId, deviceName: this.dName,
        deviceType: this.dType, deviceStatus: "1", installLocation: this.dLoc, id: this.dEditId
      };
      updateFeedingDevices(updateReq).then((): void => { ToastUtil.showToast("更新成功"); this.loadDevices(); })
        .catch((): void => ToastUtil.showToast("更新失败"));
    } else {
      const addReq: AddFeedingDevicesRequest = {
        key: this.userKey, userId: this.userId, deviceName: this.dName,
        deviceType: this.dType, deviceStatus: "1", installLocation: this.dLoc
      };
      addFeedingDevices(addReq).then((): void => { ToastUtil.showToast("绑定成功"); this.loadDevices(); })
        .catch((): void => ToastUtil.showToast("绑定失败"));
    }
  }

  private handleDeleteDevice(id: string): void {
    const req: DelFeedingDevicesRequest = { key: this.userKey, userId: this.userId, id: id };
    delFeedingDevices(req)
      .then((): void => { ToastUtil.showToast("设备已解绑"); this.loadDevices(); })
      .catch((): void => ToastUtil.showToast("解绑失败"));
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
        this.petAvatarMap[petId] = 'file://' + destPath;
        PreferencesUtil.putSync("pet_avatars", JSON.stringify(this.petAvatarMap));
        ToastUtil.showToast("头像更新成功");
      }
    } catch (err) {}
  }

  // ================= 视图层 =================
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 保持玻璃拟物化的背景和半透明模糊层
      Image($r('app.media.bg2')).width('100%').height('100%').objectFit(ImageFit.Cover)
      Column().width('100%').height('100%').backgroundColor('rgba(255, 255, 255, 0.2)').backdropBlur(30)

      Scroll() {
        Column() {
          // PC 端限制最大宽度居中排列，内部是单列上下三个模块
          Column({ space: 24 }) {
            this.PetSection()
            this.DeviceSection()
            this.ScheduleSection()
          }
          .width('100%')
          .constraintSize({ maxWidth: 1080 })
          .padding({ left: 16, right: 16, top: 24, bottom: 60 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  // ================= 模块一：宠物档案 =================
  @Builder
  private PetSection(): void {
    Column() {
      // Header
      Row() {
        // 展开/折叠点击区
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.pawprint_fill')).fontSize(24).fontColor(['#1890FF'])
          Column() {
            Text("宠物档案").fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
            Text(`共 ${this.petList.length} 个宝贝`).fontSize(12).fontColor('#888')
          }.alignItems(HorizontalAlign.Start)

          SymbolGlyph(this.isPetExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
            .fontSize(22).fontColor(['#888']).margin({ left: 4 })
        }
        .layoutWeight(1)
        .onClick((): void => {
          animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, (): void => {
            this.isPetExpanded = !this.isPetExpanded;
          });
        })

        // 独立的添加按钮区
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus')).fontSize(18).fontColor([Color.White])
        }
        .width(34).height(34).backgroundColor('#1890FF')
        .onClick((): void => { this.petDialogController.open(); })
      }
      .width('100%')
      .padding(20)

      // Content
      if (this.isPetExpanded) {
        Divider().color('rgba(0,0,0,0.05)').margin({ left: 20, right: 20 })

        Column({ space: 12 }) {
          if (this.isLoadingPets) {
            LoadingProgress().width(30).height(30).alignSelf(ItemAlign.Center).margin(16)
          } else if (this.petList.length === 0) {
            Text("暂无宠物档案").fontColor('#888').fontSize(14).margin(16)
          } else {
            // 内部列表依然采用网格适配
            GridRow({
              columns: { sm: 1, md: 2, lg: 3 },
              gutter: { x: 16, y: 16 }
            }) {
              ForEach(this.petList, (pet: PetBean) => {
                GridCol() { this.PetCard(pet) }
              })
            }
          }
        }
        .width('100%')
        .padding(20)
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private PetCard(pet: PetBean): void {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.petAvatarMap[pet.id]) {
          Image(this.petAvatarMap[pet.id]).width(52).height(52).borderRadius(26).blur(5)
          Image(this.petAvatarMap[pet.id]).width(48).height(48).borderRadius(24).objectFit(ImageFit.Cover)
        } else {
          Circle({ width: 48, height: 48 }).fill('#E8EAED')
          SymbolGlyph($r('sys.symbol.camera')).fontSize(20).fontColor(['#999'])
        }
      }
      .margin({ right: 12 })
      .onClick((): void => { this.selectAndSaveAvatar(pet.id); })

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(pet.petName).fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Black)
          Text(pet.petGender === 'male' ? '♂' : '♀').fontColor(pet.petGender === 'male' ? '#1890FF' : '#FF4D4F')
        }
        Text(`${pet.petBreed} | ${pet.currentWeight}kg`).fontSize(12).fontColor('#666')
        Text(`状态: ${pet.healthStatus}`).fontSize(11).fontColor('#52C41A')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 8 }) {
        Button({ type: ButtonType.Circle }) { SymbolGlyph($r('sys.symbol.AI_pencil')).fontSize(14).fontColor([Color.White]) }
        .width(28).height(28).backgroundColor('#FFB11B')
        .onClick((): void => { this.petDialogController.open(); })

        Button({ type: ButtonType.Circle }) { SymbolGlyph($r('sys.symbol.trash')).fontSize(14).fontColor([Color.White]) }
        .width(28).height(28).backgroundColor('#FF4D4F')
        .onClick((): void => { this.handleDeletePet(pet.id); })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.selectedPetId === pet.id ? 'rgba(24, 144, 255, 0.15)' : 'rgba(255, 255, 255, 0.6)')
    .border({ width: this.selectedPetId === pet.id ? 2 : 1, color: this.selectedPetId === pet.id ? '#1890FF' : 'rgba(255,255,255,0.8)', radius: 14 })
    .borderRadius(14)
    .onClick((): void => {
      this.selectedPetId = pet.id;
      this.loadSchedules(pet.id.toString());
    })
  }

  // ================= 模块二：设备管理 =================
  @Builder
  private DeviceSection(): void {
    Column() {
      // Header
      Row() {
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.gearshape')).fontSize(24).fontColor(['#52C41A'])
          Column() {
            Text("智能设备管理").fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
            Text(`已绑定 ${this.deviceList.length} 台设备`).fontSize(12).fontColor('#888')
          }.alignItems(HorizontalAlign.Start)

          SymbolGlyph(this.isDeviceExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
            .fontSize(22).fontColor(['#888']).margin({ left: 4 })
        }
        .layoutWeight(1)
        .onClick((): void => {
          animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, (): void => {
            this.isDeviceExpanded = !this.isDeviceExpanded;
          });
        })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus')).fontSize(18).fontColor([Color.White])
        }
        .width(34).height(34).backgroundColor('#52C41A')
        .onClick((): void => { this.openDeviceDialog(); })
      }
      .width('100%')
      .padding(20)

      // Content
      if (this.isDeviceExpanded) {
        Divider().color('rgba(0,0,0,0.05)').margin({ left: 20, right: 20 })

        Column({ space: 12 }) {
          if (this.isLoadingDevices) {
            LoadingProgress().width(30).height(30).alignSelf(ItemAlign.Center).color('#1890FF').margin(16)
          } else if (this.deviceList.length === 0) {
            Text("暂未绑定设备").fontColor('#888').fontSize(14).margin(16)
          } else {
            GridRow({ columns: { sm: 1, md: 2, lg: 3 }, gutter: { x: 16, y: 16 } }) {
              ForEach(this.deviceList, (device: DeviceBean) => {
                GridCol() { this.DeviceCard(device) }
              })
            }
          }
        }
        .width('100%')
        .padding(20)
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private DeviceCard(device: DeviceBean): void {
    Row() {
      SymbolGlyph($r('sys.symbol.gearshape')).fontSize(36).fontColor(['#52C41A']).margin({ right: 12 })

      Column({ space: 4 }) {
        Text(device.deviceName).fontSize(15).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        Text(`类型: ${device.deviceType}`).fontSize(12).fontColor('#666')
        Row({ space: 6 }) {
          Text(`位置: ${device.installLocation}`).fontSize(11).fontColor('#888')
          Text(`● 在线`).fontSize(11).fontColor('#52C41A')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 8 }) {
        Button({ type: ButtonType.Circle }) { SymbolGlyph($r('sys.symbol.AI_pencil')).fontSize(14).fontColor([Color.White]) }
        .width(28).height(28).backgroundColor('#FFB11B')
        .onClick((): void => { this.openDeviceDialog(device); })

        Button({ type: ButtonType.Circle }) { SymbolGlyph($r('sys.symbol.trash')).fontSize(14).fontColor([Color.White]) }
        .width(28).height(28).backgroundColor('#FF4D4F')
        .onClick((): void => { this.handleDeleteDevice(device.id); })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(255, 255, 255, 0.6)')
    .border({ width: 1, color: 'rgba(255,255,255,0.8)', radius: 14 })
    .borderRadius(14)
  }

  // ================= 模块三：自动投喂计划 =================
  @Builder
  private ScheduleSection(): void {
    Column() {
      // Header
      Row() {
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.timer')).fontSize(24).fontColor(['#FFB11B'])
          Column() {
            Text("自动投喂计划").fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.Black)
            Text(`共设置 ${this.scheduleList.length} 条计划`).fontSize(12).fontColor('#888')
          }.alignItems(HorizontalAlign.Start)

          SymbolGlyph(this.isScheduleExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
            .fontSize(22).fontColor(['#888']).margin({ left: 4 })
        }
        .layoutWeight(1)
        .onClick((): void => {
          animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, (): void => {
            this.isScheduleExpanded = !this.isScheduleExpanded;
          });
        })

        Row({ space: 10 }) {
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.bolt')).fontSize(16).fontColor([Color.White])
          }
          .width(34).height(34).backgroundColor('#FFB11B')
          .onClick((): void => {
            if (this.deviceList.length === 0) { ToastUtil.showToast("无可用设备"); return; }
            this.fDeviceId = this.deviceList[0].id; this.feedDialogController.open();
          })

          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.plus')).fontSize(16).fontColor([Color.White])
          }
          .width(34).height(34).backgroundColor('#FFB11B')
          .onClick((): void => {
            if (this.deviceList.length === 0) { ToastUtil.showToast("无可用设备"); return; }
            this.openScheduleDialog();
          })
        }
      }
      .width('100%')
      .padding(20)

      // Content
      if (this.isScheduleExpanded) {
        Divider().color('rgba(0,0,0,0.05)').margin({ left: 20, right: 20 })

        Column({ space: 12 }) {
          if (this.petList.length > 0) {
            Row() {
              Text("当前宠物：").fontSize(13).fontColor('#666')
              Select(this.petList.map((p: PetBean): SelectOption => { return { value: p.petName }; }))
                .selected(Math.max(0, this.petList.findIndex((p: PetBean): boolean => p.id === this.selectedPetId)))
                .value(this.petList.find((p: PetBean): boolean => p.id === this.selectedPetId)?.petName || "请选择宠物")
                .font({ size: 14, weight: FontWeight.Bold }).fontColor('#1890FF')
                .height(30).backgroundColor('rgba(255,255,255,0.6)').borderRadius(6)
                .onSelect((index: number): void => {
                  if (this.petList[index]) {
                    this.selectedPetId = this.petList[index].id;
                    this.loadSchedules(this.selectedPetId.toString());
                  }
                })
            }
            .width('100%').margin({ bottom: 8 })
          }

          if (this.isLoadingSchedules) {
            LoadingProgress().width(30).height(30).alignSelf(ItemAlign.Center).margin(16)
          } else if (this.scheduleList.length === 0) {
            Text("暂未设置喂食计划").fontColor('#888').fontSize(14).margin(16)
          } else {
            GridRow({ columns: { sm: 1, md: 2, lg: 3 }, gutter: { x: 16, y: 16 } }) {
              ForEach(this.scheduleList, (item: FeedingSchedulesBean) => {
                GridCol() { this.ScheduleCard(item) }
              })
            }
          }
        }
        .width('100%')
        .padding(20)
      }
    }
    .colGlassCardStyle()
  }

  @Builder
  private ScheduleCard(schedule: FeedingSchedulesBean): void {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.clock_fill')).fontSize(18).fontColor(['#1890FF'])
          Text(schedule.scheduleTime).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        }
        Text(`出粮: ${schedule.foodAmount}g | 备注: ${schedule.petBreed || '无'}`).fontSize(12).fontColor('#666')
        Text(`设备: ${this.deviceList.find(d => d.id === schedule.deviceId)?.deviceName || '未知设备'}`).fontSize(11).fontColor('#888')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 8 }) {
        Toggle({ type: ToggleType.Switch, isOn: schedule.isActive === true || String(schedule.isActive) === 'true' || schedule.isActive === 1 || String(schedule.isActive) === '1' })
          .onChange((isOn: boolean): void => {
            const req: UpdateFeedingSchedulesRequest = {
              key: this.userKey, userId: this.userId, id: schedule.id, petId: this.selectedPetId?.toString() || "1",
              deviceId: schedule.deviceId || (this.deviceList[0]?.id || "1"), scheduleTime: schedule.scheduleTime,
              foodAmount: schedule.foodAmount, isActive: isOn ? "1" : "0", schedulesInfo: schedule.petBreed || '常规投喂'
            };
            updateFeedingSchedules(req).then((): void => { ToastUtil.showToast(`已${isOn?'开启':'关闭'}`); schedule.isActive = isOn; })
              .catch((): void => ToastUtil.showToast("状态更新失败"));
          })

        Row({ space: 10 }) {
          Button("编辑").height(24).fontSize(11).backgroundColor('transparent').fontColor('#FFB11B').border({ width: 1, color: '#FFB11B', radius: 12 })
            .onClick((): void => { this.openScheduleDialog(schedule); })
          Button("删除").height(24).fontSize(11).backgroundColor('transparent').fontColor('#FF4D4F').border({ width: 1, color: '#FF4D4F', radius: 12 })
            .onClick((): void => { this.handleDeleteSchedule(schedule.id) })
        }
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(255, 255, 255, 0.6)')
    .border({ width: 1, color: 'rgba(255,255,255,0.8)', radius: 14 })
    .borderRadius(14)
  }
}

// ------------------- 弹窗区 -------------------

@CustomDialog
struct PetDialog {
  controller: CustomDialogController
  onConfirm: (data: PetBean) => void = (data: PetBean): void => {}

  @State pName: string = ''
  @State pBreed: string = ''
  @State pWeight: string = ''

  build() {
    Column({ space: 16 }) {
      Text("新增/编辑宠物").fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ placeholder: "宠物昵称" }).onChange((v: string): void => { this.pName = v })
      TextInput({ placeholder: "品种 (如: 英短/金毛)" }).onChange((v: string): void => { this.pBreed = v })
      TextInput({ placeholder: "体重 (kg)" }).type(InputType.Number).onChange((v: string): void => { this.pWeight = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1)
          .onClick((): void => { this.controller.close() })
        Button("保存").backgroundColor('#1890FF').layoutWeight(1)
          .onClick((): void => {
            if (!this.pName || !this.pWeight) { ToastUtil.showToast("名称和体重必填"); return; }
            this.onConfirm({
              id: -1, userId: 1, petName: this.pName, petSpecies: "猫/狗", petBreed: this.pBreed,
              petGender: "male", birthDate: "2023-01-01", currentWeight: Number(this.pWeight),
              healthStatus: "健康", createdAt: "", updatedAt: ""
            } as PetBean);
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
  @Link deviceList: DeviceBean[]
  @Link sDeviceId: string
  @Link sTime: string;
  @Link sAmount: string;
  @Link sNote: string;
  @Link sEditId: string;
  onConfirm: () => void = (): void => {}

  build() {
    Column({ space: 16 }) {
      Text(this.sEditId ? "编辑喂食计划" : "新增喂���计划").fontSize(20).fontWeight(FontWeight.Bold)

      Select(this.deviceList.map((item: DeviceBean): SelectOption => {
        return { value: item.deviceName + (item.installLocation ? ` (${item.installLocation})` : '') };
      }))
        .selected(Math.max(0, this.deviceList.findIndex((d: DeviceBean): boolean => d.id === this.sDeviceId)))
        .value(this.deviceList.find((d: DeviceBean): boolean => d.id === this.sDeviceId)?.deviceName || "选择执行设备")
        .font({ size: 14 }).fontColor(Color.Black).width('100%').height(40).backgroundColor('#F5F5F5').borderRadius(8)
        .onSelect((index: number, value: string): void => {
          if (this.deviceList[index]) this.sDeviceId = this.deviceList[index].id;
        })

      TextInput({ text: this.sTime, placeholder: "时间 (HH:mm:ss)" }).onChange((v: string): void => { this.sTime = v })
      TextInput({ text: this.sAmount, placeholder: "投喂量 (g)" }).type(InputType.Number).onChange((v: string): void => { this.sAmount = v })
      TextInput({ text: this.sNote, placeholder: "备注" }).onChange((v: string): void => { this.sNote = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1).onClick((): void => { this.controller.close() })
        Button("保存").backgroundColor('#52C41A').layoutWeight(1).onClick((): void => { this.onConfirm(); this.controller.close(); })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}

@CustomDialog
struct DeviceDialog {
  controller: CustomDialogController
  @Link dName: string;
  @Link dType: string;
  @Link dLoc: string;
  @Link dEditId: string;
  onConfirm: () => void = (): void => {}

  build() {
    Column({ space: 16 }) {
      Text(this.dEditId ? "修改设备信息" : "绑定新设备").fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ text: this.dName, placeholder: "设备名称" }).onChange((v: string): void => { this.dName = v })
      TextInput({ text: this.dType, placeholder: "设备类型" }).onChange((v: string): void => { this.dType = v })
      TextInput({ text: this.dLoc, placeholder: "安装位置" }).onChange((v: string): void => { this.dLoc = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1).onClick((): void => { this.controller.close() })
        Button("保存").backgroundColor('#1890FF').layoutWeight(1).onClick((): void => { this.onConfirm(); this.controller.close(); })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}

@CustomDialog
struct InstantFeedDialog {
  controller: CustomDialogController
  @Link deviceList: DeviceBean[]
  @Link fDeviceId: string
  onConfirm: (amount: string) => void = (amount: string): void => {}
  @State amount: string = '100'

  build() {
    Column({ space: 16 }) {
      Text("⚡ 立即定量投喂").fontSize(20).fontWeight(FontWeight.Bold)
      Text("云端设备将立即释放设定量的食物").fontSize(13).fontColor('#888')

      Select(this.deviceList.map((item: DeviceBean): SelectOption => {
        return { value: item.deviceName + (item.installLocation ? ` (${item.installLocation})` : '') };
      }))
        .selected(Math.max(0, this.deviceList.findIndex((d: DeviceBean): boolean => d.id === this.fDeviceId)))
        .value(this.deviceList.find((d: DeviceBean): boolean => d.id === this.fDeviceId)?.deviceName || "选择出粮设备")
        .font({ size: 14 }).fontColor(Color.Black).width('100%').height(40).backgroundColor('#F5F5F5').borderRadius(8)
        .onSelect((index: number, value: string): void => {
          if (this.deviceList[index]) this.fDeviceId = this.deviceList[index].id;
        })

      TextInput({ text: this.amount, placeholder: "克数 (g)" }).type(InputType.Number).onChange((v: string): void => { this.amount = v })

      Row({ space: 16 }) {
        Button("取消").backgroundColor('#E5E5E5').fontColor(Color.Black).layoutWeight(1).onClick((): void => { this.controller.close() })
        Button("出粮").backgroundColor('#FFB11B').layoutWeight(1)
          .onClick((): void => {
            if (!this.amount) { ToastUtil.showToast("请输入投喂量"); return; }
            this.onConfirm(this.amount); this.controller.close();
          })
      }
    }
    .padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}

// 恢复原始玻璃拟物化样式
@Extend(Column) function colGlassCardStyle() {
  .width('100%')
  .backgroundColor('rgba(255, 255, 255, 0.45)')
  .borderRadius(20)
  .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.8)' })
  .shadow({ radius: 15, color: 'rgba(0, 0, 0, 0.05)', offsetX: 0, offsetY: 6 })
  .clip(true)
}