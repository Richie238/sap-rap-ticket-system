@EndUserText.label: 'Ticket Category Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZI_TICKET_CATEG_VH_03 as select
from zticket_cat_03
{
    key category as Category,
    category_text as CategoryText
}
