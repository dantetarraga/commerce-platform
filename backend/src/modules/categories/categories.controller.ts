import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/auth.decorators';
import { LocationQueryDto, pointOf } from '../../common/dto/location-query.dto';
import { CategoriesService } from './categories.service';

@ApiTags('catalog')
@Public()
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categories: CategoriesService) {}

  /** `openStoreCount`: abiertos ahora que llegan a `?lat=&lng=` (o al centro). */
  @Get()
  list(@Query() location: LocationQueryDto) {
    return this.categories.list(pointOf(location));
  }
}
