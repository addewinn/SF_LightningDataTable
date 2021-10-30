# Lightning Data Table with Dynamic Data
Dynamic Lightning Datatable populated using any field set from any SObject.
- Provides Admin access to design components for choosing the SObject and Field set to render in the datatable.
    - Supports custom table header and footer via design component
    - Supports default sizing per table.  Defaults to <i>auto</i>
    - Supports selecting default sort direction and field to sort by via design component
    - admins can disable table resizing and dynamic data loading from design component

![Design Component](design_component.png?raw=true "Design Component")


- Leverages LocalStorage to store user changes to column widths
    - Seperate support for each rendition of the table.  Users can have multiple tables on the same lightning page with unique column widths.
- Supports infinite scrolling
    - Displays counter in footer location for total rows loaded/remaining
- Supports Sorting on all fields that can be sorted
- Identifies name fields and related records to establish linkName references for hyperlinking to records from table

![Infinite Loading](infinitescroll.gif?raw=true "Infinite Scroll")


- Supports DML across mixed record types in the same table

![DML](dml.png?raw=true "DML")


## TO DO's and Known Issues to Resolve

### Lightning Data Table
Provide full support for all cell attributes and types as outlined from [Lightning Datatabe Component Blueprint](https://developer.salesforce.com/docs/component-library/bundle/lightning-datatable/documentation "Component Bluerint")

### Component Bundle
- Does not handle long text fields well when sorting.  Table can spill outside of component
- Does not handle rich text fields
- Init handler on component is not calling Local Storage to size table on initial load (first view only.  Will handle properly on subsequent views)
- Default column widths are too small
- Alignment is not proper for data in columns.  Need to establish default left,right, center align for each possible field type
- Connect or otherwise remove upload and download icons from toolbar icons on data table.  They do not currently do anything.
    - was thinking this could be managed with metadata references to endpoints mapped in those settings.

### Apex
- Need to break out single controller class into sub-classes that inherit it.  All code currently resides in controller.  It is a hard read in its current state.  I wrote it in a test environment just to see if I could get it to work.

### Unit Tests
- NEED

## Apex Docs
[Apex Docs - Download folder and open Index.html](./ApexDocumentation/ "Apex Docs")
### AuraDataTableController.cls
![AuraDataTableController.cls](AuraDataTableController.png?raw=true "Aura DataTable Controller")

### AuraDataTableDesignController.cls
![AuraDataTableDesignController.cls](AuraDataTableDesignController.png?raw=true "Aura DataTable Design Controller")

## PMD
[PMD](./PMD "PMD")

# Code of Conduct
[Code of Conduct for this repository](./CODE_OF_CONDUCT.md "Code of Conduct")
