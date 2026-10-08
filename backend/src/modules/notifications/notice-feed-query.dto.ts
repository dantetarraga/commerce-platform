import { IsIn, IsOptional } from 'class-validator';
import { NOTICE_FILTERS, type NoticeFilter } from './notice-feed';

export class NoticeFeedQueryDto {
  @IsOptional()
  @IsIn(NOTICE_FILTERS, { message: 'El filtro debe ser all, orders u offers.' })
  filter: NoticeFilter = 'all';
}
