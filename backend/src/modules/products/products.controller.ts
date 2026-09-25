import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/auth.decorators';
import { LocationQueryDto, pointOf } from '../../common/dto/location-query.dto';
import { ProductsService } from './products.service';

@ApiTags('catalog')
@Public()
@Controller('products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @Get(':id')
  detail(@Param('id') id: string, @Query() location: LocationQueryDto) {
    return this.products.detail(id, pointOf(location));
  }
}
