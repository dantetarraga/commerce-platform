import { mockDeep } from 'jest-mock-extended';
import type { PrismaService } from '../../../database/prisma.service';
import type { City, Prisma, User } from '../../../generated/prisma/client';
import type { TokensService } from '../../auth/tokens/tokens.service';
import { AdminPartnersService } from './admin-partners.service';
import type { CreateCourierDto } from './partners.dto';

function setup() {
  const prisma = mockDeep<PrismaService>();
  const tx = mockDeep<Prisma.TransactionClient>();
  prisma.$transaction.mockImplementation((work) => work(tx));
  tx.city.findUnique.mockResolvedValue({ id: 'espinar' } as City);
  tx.user.findUnique.mockResolvedValue({ id: 'courier-user', isActive: true } as User);
  const account = {
    id: 'courier-user',
    phone: '987654321',
    firstName: 'Ana',
    lastName: 'Quispe',
    isActive: true,
    roles: [{ role: 'COURIER' }],
    ownedStores: [],
    courier: null,
  };
  tx.user.findUniqueOrThrow.mockResolvedValue(account as unknown as User);
  return { tx, service: new AdminPartnersService(prisma, mockDeep<TokensService>()) };
}

const dto: CreateCourierDto = {
  phone: '987654321',
  firstName: 'Ana',
  lastName: 'Quispe',
  cityId: 'espinar',
  vehicleType: 'MOTO',
  vehicleLabel: 'Moto azul',
  plate: 'ABC-123',
};

describe('AdminPartnersService.createCourier', () => {
  it('conserva la antigüedad al editar el vehículo sin enviar el año', async () => {
    const { service, tx } = setup();
    await service.createCourier(dto);
    const update = tx.courier.upsert.mock.calls[0][0].update;
    expect(update).toMatchObject({ vehicleLabel: 'Moto azul', plate: 'ABC-123' });
    expect(update).not.toHaveProperty('activeSince');
  });

  it('permite actualizar la antigüedad cuando el año se envía explícitamente', async () => {
    const { service, tx } = setup();
    await service.createCourier({ ...dto, activeSince: 2020 });
    expect(tx.courier.upsert.mock.calls[0][0].update).toMatchObject({ activeSince: 2020 });
  });
});
