/// API pública de `orders` para las dos apps (UI en `orders_customer`/`orders_staff`).
library;

export 'orders_domain.dart';
export 'presentation/order_status_labels.dart';
export 'presentation/providers/orders_providers.dart'
    show activeOrderIdProvider, activeOrderProvider, fakeStaffOrdersProvider, ordersHistoryProvider, ordersRepositoryProvider, ordersSummaryProvider;
