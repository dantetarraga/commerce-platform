import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { CityDto, UpdateCityDto } from './admin-cities.dto';
import { AdminCitiesService } from './admin-cities.service';

/** Ciudades: zona de reparto, tarifas y velocidad para el tiempo estimado. */
@ApiTags('admin · ciudades')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin/cities')
export class AdminCitiesController {
  constructor(private readonly cities: AdminCitiesService) {}

  /** Todas, con cuántos negocios y repartidores tienen y ejemplos de tarifa. */
  @Get()
  list() {
    return this.cities.list();
  }

  /** Nace inactiva salvo que se pida lo contrario. */
  @Post()
  create(@Body() dto: CityDto) {
    return this.cities.create(dto);
  }

  /** `isActive: false` falla si quedan pedidos en curso. */
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCityDto) {
    return this.cities.update(id, dto);
  }
}
