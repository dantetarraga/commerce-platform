/// API pública del feature `orders`: pedidos, seguimiento e historial.
library;

export 'domain/order.dart';
export 'domain/staff_order.dart';
export 'infrastructure/datasources/fake_staff_orders.dart' show FakeStaffOrders;
export 'infrastructure/models/order_json.dart' show OrderJson;
export 'infrastructure/models/staff_order_json.dart' show StaffOrderJson;
export 'presentation/pages/order_help_page.dart';
export 'presentation/pages/order_tracking_page.dart';
export 'presentation/pages/orders_page.dart';
export 'presentation/providers/orders_providers.dart'
    show activeOrderIdProvider, activeOrderProvider, fakeStaffOrdersProvider, ordersHistoryProvider, ordersRepositoryProvider, recentOrdersByStoreProvider;
export 'presentation/widgets/staff_order_widgets.dart';
