# SF_LightningDataTable
Dynamic Lightning Datatable populated using any field set from any SObject.
- Provides Admin access to design components for choosing the SObject and Field set to render in the datatable.

[Design Component ](./docs/design_component.png)

- Leverages LocalStorage to store user changes to column widths
    - Seperate support for each rendition of the table.  Users can have multiple tables on the same lightning page with unique column widths.
- Supports dynamic data loading
    - Displays counter in footer location for total rows loaded/remaining
- Supports custom table header and footer via design component
- Supports default sizing per table.  Defaults to <i>auto</i>
- Supports DML across mixed record types in the same table
- Supports selecting default sort direction and field to sort by via design component
- admins can disable table resizing and dynamic data loading from design component
- 

## Aura Component 
<b>U_DataTable.cmp</b>
