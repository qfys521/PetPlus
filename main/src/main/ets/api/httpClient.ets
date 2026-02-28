import axios, {
  AxiosError,
  AxiosRequestConfig,
  AxiosResponse,
  Method
} from '@ohos/axios';
import { ApiError, ResponseBean } from './types';
import { LogUtil } from '@pura/harmony-utils';

export interface RequestOptions {
  method: string;
  params?: Object;
  data?: Object;
  headers?: Object;
  timeout?: number;
}

/**
 * 全局请求方法
 */
export async function request<T>(
  baseUrl: string,
  endpoint: string,
  options: RequestOptions
): Promise<T> {

  const fullUrl = `${baseUrl}${endpoint}`;
  const startTime = Date.now();

  try {
    const config: AxiosRequestConfig = {
      baseURL: baseUrl,
      url: endpoint,
      method: options.method as Method,
      params: options.params,
      data: options.data,
      headers: options.headers as Record<string, string>,
      timeout: options.timeout ?? 30000
    };




    LogUtil.info(`
URL: ${fullUrl}
Method: ${options.method}
Params: ${JSON.stringify(options.params)}
Data: ${JSON.stringify(options.data)}
`);

    const response: AxiosResponse<ResponseBean<T>> =
      await axios.request(config);

    LogUtil.info(`
URL: ${fullUrl}
Status: ${response.status}
Response: ${JSON.stringify(response.data)}
Time: ${Date.now() - startTime} ms
`);


    if (response.status !== 200) {
      LogUtil.error(`[HTTP ERROR] 状态异常: ${response.status}`);
      throw new ApiError(response.status, `HTTP状态异常: ${response.status}`);
    }

    const result = response.data;
    const businessCode = Number(result.code);


    if (businessCode !== 1) {
      LogUtil.error(`
URL: ${fullUrl}
Business Code: ${businessCode}
Message: ${result.message}
`);
      throw new ApiError(
        businessCode || -1,
        result.message || '业务处理失败'
      );
    }


    return result.data;

  } catch (err) {




    if (axios.isAxiosError(err)) {
      const axiosErr = err as AxiosError<Object, Object>;

      LogUtil.error(`
URL: ${fullUrl}
Status: ${axiosErr.response?.status}
Message: ${axiosErr.message}
`);

      throw new ApiError(
        axiosErr.response?.status || -1,
        `网络异常: ${axiosErr.message}`
      );
    }




    if (err instanceof ApiError) {
      LogUtil.error(`
URL: ${fullUrl}
Code: ${err.code}
Message: ${err.message}
`);
      throw err;
    }




    const errObj = err as Error;

    LogUtil.error(`
URL: ${fullUrl}
Message: ${errObj.message}
`);

    throw new ApiError(-1, errObj.message || '未知错误');

  } finally {



    LogUtil.info(`
URL: ${fullUrl}
Total Time: ${Date.now() - startTime} ms
`);
  }
}