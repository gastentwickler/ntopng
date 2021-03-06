--
-- (C) 2013-20 - ntop.org
--


print('<link href="'.. ntop.getHttpPrefix()..'/datatables/datatables.min.css" rel="stylesheet"/>')

print [[

<table id="periodicity_info" class="table table-bordered table-striped w-100">
        <thead>
            <tr>
                <th>]] print(i18n("protocol")) print [[</th>
                <th>]] print(i18n("client")) print [[</th>
                <th>]] print(i18n("server")) print [[</th>
                <th>]] print(i18n("port")) print [[</th>
                <th>]] print(i18n("observations")) print [[</th>
                <th>]] print(i18n("frequency")) print [[</th>
            </tr>
        </thead>
</table>
<p>

<script>
$(document).ready(function() {
  let url    = ']] print(ntop.getHttpPrefix()) print [[/lua/get_periodicity_data.lua';
  let config = DataTableUtils.getStdDatatableConfig();

  config     = DataTableUtils.setAjaxConfig(config, url, 'data');

config["columnDefs"] = [ 

{ targets: [ 5 ], className: 'dt-body-right', "fnCreatedCell": function ( cell ) { cell.scope = 'row'; }, "render": function ( data, type, row ) { return (type == "sort" || type == 'type') ? data : data+" sec"; }  },
{ targets: [ 4 ], className: 'dt-body-right', "fnCreatedCell": function ( cell ) { cell.scope = 'row'; } }

];

  $('#periodicity_info').DataTable(config);
} );

 i18n.showing_x_to_y_rows = "]] print(i18n('showing_x_to_y_rows', {x='_START_', y='_END_', tot='_TOTAL_'})) print[[";

</script>
]]
