import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { App, window } from '@kit.ArkUI';
import { AppUtil, LogUtil } from '@pura/harmony-utils';
import { DialogHelper } from '@pura/harmony-dialog';

const DOMAIN = 0x0000;

export default class MainAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    console.debug("初始化 harmony-utils 中...")
    try{
      AppUtil.init(this.context)
      LogUtil.setTag("PetPlus")
    }catch (err){
      console.error("初始化 harmony-utils 失败..." , err)

      App.terminate()
    }

    console.debug("初始化 harmony-dialog 中...")
    try {
      DialogHelper.setDefaultConfig((config) => {
        config.uiAbilityContext = this.context;
      })
    }catch (err){
      console.error("初始化 harmony-dialog 失败..." , err)
      App.terminate()
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');


    try {

      let windowClass = windowStage.getMainWindowSync();


      windowClass.setWindowLayoutFullScreen(true);


      let sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarContentColor: '#FFFFFF'
      };


      windowClass.setWindowSystemBarProperties(sysBarProps);

      hilog.info(DOMAIN, 'testTag', 'Succeeded in setting the window layout to full-screen.');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set the window layout to full-screen. Cause: %{public}s', JSON.stringify(err));
    }


    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}