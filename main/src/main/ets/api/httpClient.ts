// api/httpClient.ts
import axios, { AxiosError, AxiosRequestConfig, AxiosResponse, Method } from '@ohos/axios';
import { ApiError, ResponseBean } from './types';

/**
 * 通用 HTTP 客户端（基于 @ohos/axios 封装）
 */
export async function request<T>(
  baseUrl: string,
  endpoint: string,
  options: {
    method: string; // 兼容原生 http.RequestMethod 定义（如 "POST", "GET" 等）
    params?: Record<string, string | number | boolean>;
    data?: object;
    headers?: Record<string, string>;
    timeout?: number;
  }
): Promise<T> {

  try {
    // 构造 Axios 请求配置
    const config: AxiosRequestConfig = {
      baseURL: baseUrl,
      url: endpoint,
      method: options.method as Method,
      // Axios 会自动帮我们把 params 对象转化为 URL 参数拼接并进行 Encode 处理
      params: options.params,
      // data 会被自动转换为 JSON 并放到请求体中
      data: options.data,
      headers: Object.assign({
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }, options.headers || {}),
      timeout: options.timeout ?? 30000
    };

    // 发起网络请求
    const response: AxiosResponse<ResponseBean<T>> = await axios.request(config);

    // Axios 默认只有 2xx 状态码才会进入此区块，直接取出业务数据
    const result = response.data;

    // 返回泛型 T 数据（你的原始结构 ResponseBean<T>，其中包含实际数据 data）
    return result.data;

  } catch (err) {
    // 捕获之前定义的 ApiError 直接抛出
    if (err instanceof ApiError) {
      throw err;
    }

    // 捕获 Axios 包装的异常
    if (axios.isAxiosError(err)) {
      const axiosErr = err as AxiosError;
      const status = axiosErr.response?.status || -1;
      const message = axiosErr.message || '网络请求错误';
      throw new ApiError(status, `HTTP Error: ${status} - ${message}`);
    }

    // 其他未知异常
    throw new ApiError(-1, '网络异常或未知错误');
  }
}