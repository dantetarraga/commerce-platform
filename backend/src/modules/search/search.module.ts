import { Module } from '@nestjs/common';
import { CitiesModule } from '../cities/cities.module';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

@Module({
  imports: [CitiesModule],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
