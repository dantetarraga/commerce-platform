import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/auth.decorators';
import { LocationQueryDto, pointOf } from '../../common/dto/location-query.dto';
import { SearchQueryDto } from './dto/search-query.dto';
import { SearchService } from './search.service';

@ApiTags('catalog')
@Public()
@Controller()
export class SearchController {
  constructor(private readonly search: SearchService) {}

  /** Negocios + productos en una llamada, para la pantalla Buscar. */
  @Get('search')
  find(@Query() query: SearchQueryDto) {
    return this.search.search(query.q, pointOf(query), query.openOnly);
  }

  @Get('discovery/local-products')
  localProducts(@Query() location: LocationQueryDto) {
    return this.search.localProducts(pointOf(location));
  }

  @Get('discovery/popular-searches')
  popularSearches(@Query() location: LocationQueryDto) {
    return this.search.popularSearches(pointOf(location));
  }
}
