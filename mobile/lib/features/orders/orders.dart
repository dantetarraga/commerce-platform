/// API pública del feature `orders`, compartida por las dos apps: dominio,
/// etiquetas de estado y providers. La UI de cada app va en `orders_customer.dart` y
/// `orders_staff.dart`; los modelos JSON en `orders_infrastructure.dart`.
library;

export 'domain/order.dart';
export 'domain/staff_order.dart';
export 'presentation/order_status_labels.dart';
export 'presentation/providers/orders_providers.dart'
    show activeOrderIdProvider, activeOrderProvider, fakeStaffOrdersProvider, ordersHistoryProvider, ordersRepositoryProvider, recentOrdersByStoreProvider;
