import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/auth.decorators';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { AddressesService } from './addresses.service';
import { AddressBookDto } from './dto/address-book.dto';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users/me/addresses')
export class AddressesController {
  constructor(private readonly addresses: AddressesService) {}

  /** `{ selectedId, addresses }`, con los ids de la app. */
  @Get()
  book(@CurrentUser() user: AuthUser) {
    return this.addresses.book(user.id);
  }

  @Put()
  replace(@CurrentUser() user: AuthUser, @Body() dto: AddressBookDto) {
    return this.addresses.replace(user.id, dto);
  }
}
