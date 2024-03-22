-- We start a GraphViz graph
SELECT '
digraph structs {
'
UNION ALL

-- Normally, GraphViz' "dot" command lays out a hierarchical graph from
-- top to bottom.  However, we aren't just laying out individual nodes,
-- each node is a vertical list of database fields.  To prevent GraphViz
-- from snaking arrows all over the place, we constrain it to draw
-- incoming references on the left of each field, and outgoing references
-- on the right.  Since that's the way references flow for each database
-- table, we tell GraphViz to lay the whole graph out left-to-right,
-- which makes its job much easier and produces prettier output.
SELECT '
rankdir="LR"
'
UNION ALL


-- By default, nodes have circles around them.  We will draw our own
-- tables below, we do not want the circles.
SELECT '
node [shape=none]
'
UNION ALL

-- This is the big query that renders a node complete with field names
-- for each table in the database.  Because we want raw GraphViz output,
-- our query returns rows with a single string field, whose value is a
-- complex calculation using SQL as a templating engine.  This is kind
-- of an abuse, but works nicely nevertheless.
SELECT
    CASE
        -- When the previous row's table name is the same as this one,
        -- do nothing.
        WHEN LAG(t.name, 1) OVER (ORDER BY t.name) = t.name THEN ''

        -- Otherwise, this is the first row of a new table, so start
        -- the node markup and add a header row.  Normally in GraphViz,
        -- the table name would *be* the label of the node, but since
        -- we're using the label to represent the entire node, we have
        -- to make our own header.
        --
        -- GraphViz does have a "record" label shape, but it seems tricky
        -- to work with and I found the HTML-style label markup easier
        -- to get working the way I wanted.
        ELSE
            t.name || ' [label=<
            <TABLE BORDER="0" CELLSPACING="0" CELLBORDER="1">
                <TR>
                    <TD COLSPAN="2"><B>' || t.name || '</B></TD>
                </TR>
            '

    -- After the header (if needed), we have rows for each field in
    -- the table.
    --
    -- The "pk" metadata field is zero for table fields that are not part
    -- of the primary key.  If the "pk" metadata field is 1 or more, that
    -- tells you that table field's order in the (potentially composite)
    -- primary key.
    --
    -- We also add ports to each of the table cells, so that we can
    -- later tell GraphViz to specifically connect the ports representing
    -- specific fields in each table, instead of connecting the tables
    -- generally.
    END || '
                <TR>
                    <TD PORT="' || i.name || '_to">' ||
                        CASE i.pk WHEN 0 THEN '&nbsp;' ELSE '🔑' END ||
                    '</TD>
                    <TD PORT="' || i.name || '_from">' || i.name || '</TD>
                </TR>
            ' ||
    CASE
        -- When the next row's table name is the same as this one,
        -- do nothing.
        WHEN LEAD(t.name, 1) OVER (ORDER BY t.name) = t.name THEN ''

        -- Otherwise, this is the last row of a database table, so end
        -- the table markup.
        ELSE '
            </TABLE>
        >];
        '
    END

-- This is how you get nice relational data out of SQLite's metadata
-- pragmas.
FROM pragma_table_list() AS t
    JOIN pragma_table_info(t.name, t.schema) AS i

WHERE
    -- SQLite has a bunch of metadata tables in each schema, which
    -- are hidden from .tables and .schema but which are reported
    -- in pragma_table_list().  They're not user-created and almost
    -- certainly user databases don't have foreign keys to them, so
    -- let's just filter them out.
    t.name NOT LIKE 'sqlite_%'

    -- Despite its name, pragma_table_list() also includes views.
    -- Since those don't store any information or have any correctness
    -- constraints, they're just distracting if you're trying to quickly
    -- understand a database's schema, so we'll filter them out too.
    AND t.type = 'table'
UNION ALL

-- Now we have all the database tables set up, we can draw the links
-- between them.  SQLite gives us the pragma_foreign_key_list() function
-- which (for a given source table) gives us all the information we need
-- to know.  We just do a bit more string concatenation to build up the
-- GraphViz syntax equivalent.
--
-- Note that we use the ports we defined above, as well as the directional
-- overrides :e and :w, to force GraphViz to give us a layout that's
-- likely to be readable.
SELECT
    t.name || ':' || f."from" || '_from:e -> ' ||
    f."table" || ':' || f."to" || '_to:w'
FROM pragma_table_list() AS t
    JOIN pragma_foreign_key_list(t.name, t.schema) AS f
UNION ALL

-- Lastly, we close the GraphViz graph.
SELECT '
}';
