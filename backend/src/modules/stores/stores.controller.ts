import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/auth.decorators';
import { LocationQueryDto, pointOf } from '../../common/dto/location-query.dto';
import { MenuSearchQueryDto } from './dto/menu-search-query.dto';
import { StoresQueryDto } from './dto/stores-query.dto';
import { StoresService } from './stores.service';

@ApiTags('catalog')
@Public()
@Controller('stores')
export class StoresController {
  constructor(private readonly stores: StoresService) {}

  @Get()
  list(@Query() query: StoresQueryDto) {
    return this.stores.list(query, pointOf(query));
  }

  @Get(':id')
  detail(@Param('id') id: string, @Query() location: LocationQueryDto) {
    return this.stores.detail(id, pointOf(location));
  }

  @Get(':id/products')
  menu(@Param('id') id: string) {
    return this.stores.menu(id);
  }

  /** `{ items }`: lo que coincide con `?q=` en la carta, en su orden. */
  @Get(':id/products/search')
  searchMenu(@Param('id') id: string, @Query() query: MenuSearchQueryDto) {
    return this.stores.searchMenu(id, query.q);
  }
}
