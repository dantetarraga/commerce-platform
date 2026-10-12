import { imageKey } from './image-keys';

describe('imageKey', () => {
  it('las fotos de un negocio van en su carpeta', () => {
    expect(imageKey('product', 'image/webp', 'abc', 's1')).toBe('stores/s1/products/abc.webp');
    expect(imageKey('store-logo', 'image/png', 'abc', 's1')).toBe('stores/s1/logo/abc.png');
    expect(imageKey('store-cover', 'image/jpeg', 'abc', 's1')).toBe('stores/s1/cover/abc.jpg');
  });

  it('promociones y categorías no dependen de un negocio', () => {
    expect(imageKey('promotion', 'image/webp', 'abc')).toBe('promotions/abc.webp');
    expect(imageKey('category', 'image/png', 'abc')).toBe('categories/abc.png');
  });

  it('una foto de negocio sin negocio es un error de programación', () => {
    expect(() => imageKey('product', 'image/webp', 'abc')).toThrow();
  });
});
