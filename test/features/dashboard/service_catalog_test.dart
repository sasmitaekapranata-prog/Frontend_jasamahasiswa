import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/service_catalog.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/seller_service_store.dart';

void main() {
  test('seller services expose their uploaded cover and creator profile', () {
    final store = SellerServiceStore.instance;
    store.add(
      title: 'Jasa baru',
      price: 25000,
      category: 'Desain',
      description: 'Jasa desain untuk tugas.',
      deliverables: const ['File desain'],
      status: SellerServiceStatus.active,
      coverName: 'cover.png',
      coverBytes: Uint8List.fromList([1, 2, 3]),
      packageName: 'Paket dasar',
      deliveryDays: 2,
      revisions: 1,
    );
    final created = store.services.first;

    try {
      final service = ServiceCatalog.byId(created.id);

      expect(service, isNotNull);
      expect(service!.seller, created.sellerName);
      expect(service.coverBytes, same(created.coverBytes));
      expect(
        ServiceCatalog.forSeller(service).map((item) => item.id),
        contains(created.id),
      );
    } finally {
      store.delete(created.id);
    }
  });
}
