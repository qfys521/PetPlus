/**
 * API服务测试文件
 */
import { describe, it, expect } from '@ohos/hypium';
import { AuthService } from '../services/api/AuthService';
import { HttpClient } from '../services/api/HttpClient';

export default function apiServiceTest() {
  describe('AuthService Test', () => {
    let authService: AuthService;

    it('should create AuthService instance', () => {
      authService = AuthService.getInstance();
      expect(authService).assertNotNull();
    });

    it('should validate email format correctly', () => {
      // 测试有效的邮箱
      expect(AuthService.isValidEmail('test@example.com')).assertTrue();
      expect(AuthService.isValidEmail('user.name@domain.co.uk')).assertTrue();
      
      // 测试无效的邮箱
      expect(AuthService.isValidEmail('invalid-email')).assertFalse();
      expect(AuthService.isValidEmail('test@')).assertFalse();
      expect(AuthService.isValidEmail('@example.com')).assertFalse();
    });

    it('should validate password strength correctly', () => {
      // 测试密码验证
      const shortPassword = AuthService.validatePassword('123');
      expect(shortPassword.isValid).assertFalse();
      expect(shortPassword.message).assertContain('不能少于6个字符');

      const validPassword = AuthService.validatePassword('password123');
      expect(validPassword.isValid).assertTrue();
      expect(validPassword.message).assertContain('符合要求');

      const emptyPassword = AuthService.validatePassword('');
      expect(emptyPassword.isValid).assertFalse();
      expect(emptyPassword.message).assertContain('不能为空');
    });

    it('should handle login validation', async () => {
      authService = AuthService.getInstance();
      
      // 测试缺少必要字段的情况
      try {
        await authService.login({ email: '', password: 'password' });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('邮箱和密码都是必填项');
      }

      try {
        await authService.login({ email: 'test@example.com', password: '' });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('邮箱和密码都是必填项');
      }

      // 测试邮箱格式验证
      try {
        await authService.login({ email: 'invalid-email', password: 'password123' });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('邮箱格式不正确');
      }
    });

    it('should handle registration validation', async () => {
      authService = AuthService.getInstance();
      
      // 测试缺少必要字段的情况
      try {
        await authService.register({ 
          username: '', 
          email: 'test@example.com', 
          password: 'password123' 
        });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('用户名、邮箱和密码都是必填项');
      }

      // 测试密码长度不足的情况
      try {
        await authService.register({ 
          username: 'testuser', 
          email: 'test@example.com', 
          password: '123' 
        });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('密码长度不能少于6个字符');
      }

      // 测试用户名长度验证
      try {
        await authService.register({ 
          username: 'a', 
          email: 'test@example.com', 
          password: 'password123' 
        });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('用户名长度不能少于2个字符');
      }

      // 测试邮箱格式验证
      try {
        await authService.register({ 
          username: 'testuser', 
          email: 'invalid-email', 
          password: 'password123' 
        });
        expect(false).assertTrue(); // 不应该到达这里
      } catch (error) {
        expect(error.message).assertContain('邮箱格式不正确');
      }
    });
  });

  describe('HttpClient Test', () => {
    it('should create HttpClient instance', () => {
      const httpClient = HttpClient.getInstance();
      expect(httpClient).assertNotNull();
    });

    it('should handle token management', () => {
      const httpClient = HttpClient.getInstance();
      
      // 设置token
      httpClient.setToken('test-token');
      // 注意：由于token是私有属性，这里无法直接测试
      
      // 清除token
      httpClient.clearToken();
      // 同样无法直接测试私有属性
    });
  });
}