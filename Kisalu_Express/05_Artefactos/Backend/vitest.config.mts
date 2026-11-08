import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globalSetup: ['tests/global-setup.ts'],
    fileParallelism: false,
    testTimeout: 20000,
    env: { NODE_ENV: 'test', DB_NAME: 'kisalu_express_test', UPLOAD_DIR: 'tests/.uploads', PRIVADO_DIR: 'tests/.privado', CODIGO_QR_FIXO_DEV: '' },
  },
});
