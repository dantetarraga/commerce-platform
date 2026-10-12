import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/fake/fake_backend.dart';
import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/fake_merchant_menu.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/menu_remote_data_source.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/menu_repository_impl.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/models/menu_json.dart';
import 'package:apamuy/features/orders/orders_infrastructure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _store = 'st_chaski_dorado';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API', () {
    late _MockApiClient api;
    late ApiMenuRemoteDataSource remote;

    setUp(() {
      api = _MockApiClient();
      remote = ApiMenuRemoteDataSource(api);
      when(() => api.post(any(), body: any(named: 'body'))).thenAnswer((_) async => <String, dynamic>{});
      when(() => api.patch(any(), body: any(named: 'body'))).thenAnswer((_) async => <String, dynamic>{});
      when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => <Object>[]);
    });

    test('ordena las secciones de una vez y cambia solo la foto', () async {
      await remote.reorderSections(_store, ['ms_2', 'ms_1']);
      verify(
        () => api.put(
          '/merchant/catalog/stores/$_store/sections/order',
          body: {
            'sectionIds': ['ms_2', 'ms_1'],
          },
        ),
      ).called(1);
      await MenuRepositoryImpl(remote).setPhoto('pr_1', 'https://img.apamuy.pe/a.webp');
      verify(
        () => api.patch('/merchant/catalog/products/pr_1', body: {'imageUrl': 'https://img.apamuy.pe/a.webp'}),
      ).called(1);
    });

    test('la revisión trae qué cambia y el precio de antes', () {
      final result = MenuJson.importResult({
        'dryRun': true,
        'created': 1,
        'updated': 1,
        'unchanged': 0,
        'failed': 0,
        'rows': [
          {
            'line': 2,
            'name': 'Pollo',
            'action': 'update',
            'changes': ['price', 'stock', 'algo-nuevo'],
            'price': {
              'from': {'amount': 6500, 'currency': 'PEN'},
              'to': {'amount': 7000, 'currency': 'PEN'},
            },
          },
          {
            'line': 3,
            'name': 'Té',
            'action': 'create',
            'price': {
              'from': null,
              'to': {'amount': 250, 'currency': 'PEN'},
            },
          },
        ],
      });
      final update = result.withAction(ImportAction.update).single;
      expect(update.changes, [ImportChange.price, ImportChange.stock]);
      expect((update.priceFrom, update.priceTo), (const Money(6500), const Money(7000)));
      final create = result.withAction(ImportAction.create).single;
      expect((create.priceFrom, create.priceTo), (null, const Money(250)));
    });

    test('usa los endpoints del Portal Socios', () async {
      await remote.createProduct(_store, {'name': 'Té'});
      verify(() => api.post('/merchant/catalog/stores/$_store/products', body: {'name': 'Té'})).called(1);
      await remote.renameSection('ms_1', 'Bebidas');
      verify(() => api.patch('/merchant/catalog/sections/ms_1', body: {'name': 'Bebidas'})).called(1);
      await remote.importProducts(_store, [
        {'line': 2, 'name': 'Té'},
      ], dryRun: true);
      verify(
        () => api.post(
          '/merchant/catalog/stores/$_store/products/import',
          body: {
            'rows': [
              {'line': 2, 'name': 'Té'},
            ],
            'dryRun': true,
          },
        ),
      ).called(1);
    });

    test('al editar no manda variantes, y sin precio no toca el de las variantes', () {
      const draft = ProductDraft(name: '1/4 de pollo', price: null, isAvailable: true, sectionId: 'ms_1');
      final body = MenuJson.draft(draft, currency: 'PEN');
      expect(body.keys, isNot(contains('variants')));
      expect(body.keys, isNot(contains('basePrice')));
      expect(
        MenuJson.draft(
          const ProductDraft(name: 'Té', price: Money(250), isAvailable: false),
          currency: 'PEN',
        )['basePrice'],
        {'amount': 250, 'currency': 'PEN'},
      );
    });
  });

  group('demo', () {
    late FakeBackend backend;
    late MenuRepositoryImpl repo;
    late FakeStaffOrders staff;

    setUp(() {
      backend = FakeBackend(latency: Duration.zero);
      repo = MenuRepositoryImpl(FakeMenuRemoteDataSource(FakeMerchantMenu(backend)));
      staff = FakeStaffOrders(backend, newOrderEvery: Duration.zero);
    });

    Future<StoreMenu> menu() async => (await repo.menu(_store)).getOrThrow();

    test('la carta editable trae secciones y productos con su sección', () async {
      final value = await menu();
      expect(value.sections.map((s) => s.name), ['Pollos a la brasa', 'Combos', 'Bebidas']);
      final cuarto = value.products.firstWhere((p) => p.name == '1/4 de pollo a la brasa');
      expect(cuarto.hasVariants, isTrue);
      expect(cuarto.sectionId, 'ms_cd_pollos');
    });

    test('lo que se crea, edita o quita se ve en la lista de productos de Socios', () async {
      final current = await menu();
      final section = (await repo.createSection(_store, 'Postres')).getOrThrow();
      await repo.createProduct(
        _store,
        ProductDraft(name: 'Mazamorra morada', price: const Money(400), isAvailable: true, sectionId: section.id),
        currency: current.currency,
      );
      final inca = current.products.firstWhere((p) => p.name == 'Inca Kola 1.5 L');
      await repo.removeProduct(inca.id);

      final list = await staff.products(_store);
      final sections = (list['sections'] as List).cast<Map<String, dynamic>>();
      expect(sections.map((s) => s['name']), contains('Postres'));
      final names = [
        for (final s in sections)
          for (final p in (s['items'] as List).cast<Map<String, dynamic>>()) p['name'],
      ];
      expect(names, contains('Mazamorra morada'));
      expect(names, isNot(contains('Inca Kola 1.5 L')));

      // La disponibilidad que se cambia en la lista llega a la carta editable.
      final pollo = current.products.firstWhere((p) => p.name == 'Pollo entero a la brasa');
      await staff.setProductAvailable(pollo.id, available: false);
      expect((await menu()).product(pollo.id)!.isAvailable, isFalse);
    });

    test('importar revisa sin guardar y luego crea y actualiza por nombre', () async {
      const rows = [
        ImportRow(line: 2, cells: {'name': 'POLLO ENTERO A LA BRASA', 'price': '70'}),
        ImportRow(line: 3, cells: {'name': 'Emoliente', 'price': '2,50', 'section': 'Calientes'}),
      ];
      final preview = (await repo.importProducts(_store, rows, dryRun: true)).getOrThrow();
      expect(preview, isA<ImportResult>().having((r) => r.pending, 'pending', 2));
      expect(preview.sectionsCreated, ['Calientes']);
      expect((await menu()).products.where((p) => p.name == 'Emoliente'), isEmpty);

      final bad = await repo.importProducts(_store, const [
        ImportRow(line: 2, cells: {'name': 'Sin precio'}),
      ], dryRun: true);
      expect(bad.getOrThrow().rows.single.errors, ['Falta el precio: es un producto nuevo.']);
      final pollo = preview.withAction(ImportAction.update).single;
      expect((pollo.priceFrom, pollo.priceTo), (const Money(6500), const Money(7000)));
      expect(pollo.changes, [ImportChange.price]);

      await repo.importProducts(_store, rows, dryRun: false);
      final after = await menu();
      expect(after.products.firstWhere((p) => p.name == 'Emoliente').price, const Money(250));
      expect(after.products.firstWhere((p) => p.id == 'pr_pollo_entero').price, const Money(7000));
    });

    test('el orden de las secciones llega a la lista de productos', () async {
      final ids = (await menu()).sections.map((s) => s.id).toList();
      expect((await repo.reorderSections(_store, ids.reversed.toList())).isOk, isTrue);
      expect((await menu()).sections.map((s) => s.name), ['Bebidas', 'Combos', 'Pollos a la brasa']);
      final list = await staff.products(_store);
      expect((list['sections'] as List).cast<Map<String, dynamic>>().first['name'], 'Bebidas');
      // Faltan secciones: no cambia nada.
      expect((await repo.reorderSections(_store, ids.take(2).toList())).isOk, isFalse);
    });

    test('la foto puesta desde la lista saca el producto de «sin foto»', () async {
      final current = await menu();
      await repo.updateProduct(
        'pr_pollo_entero',
        const ProductDraft(name: 'Pollo entero a la brasa', price: Money(6500), isAvailable: true),
        currency: current.currency,
      );
      final before = await staff.products(_store, status: 'no_photo');
      final noPhoto = (before['counts'] as Map)['noPhoto'] as int;
      expect(noPhoto, greaterThan(0));

      await repo.setPhoto('pr_pollo_entero', '/tmp/pollo.jpg');
      final after = await staff.products(_store, status: 'no_photo');
      expect((after['counts'] as Map)['noPhoto'], noPhoto - 1);
      expect((await menu()).product('pr_pollo_entero')!.imageUrl, '/tmp/pollo.jpg');
    });

    test('en la demo la foto se queda en el teléfono', () async {
      final url = await repo.uploadPhoto(_store, const PickedPhoto(path: '/tmp/foto.jpg', contentType: 'image/jpeg'));
      expect(url.getOrThrow(), '/tmp/foto.jpg');
    });
  });

  test('PickedPhoto reconoce el tipo por la extensión', () {
    expect(PickedPhoto.fromPath('/a/b/IMG_1.JPG')?.contentType, 'image/jpeg');
    expect(PickedPhoto.fromPath('/a/b/foto.webp')?.contentType, 'image/webp');
    expect(PickedPhoto.fromPath('/a/b/foto.heic'), isNull);
  });
}
