%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust
from contracts.ships.basic_ship.library import BasicShip
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.test.grid_helper_old import grid_helper

func new_dust_cell() -> (cell : Cell):
    let cell = Cell(dust_count=1, dust=Dust(Vector2(1, 0)), ship_id=0)
    return (cell)
end

func new_ship_cell(ship_id : felt) -> (cell : Cell):
    let cell = Cell(dust_count=0, dust=Dust(Vector2(0, 0)), ship_id=ship_id)
    return (cell)
end

@external
func test_no_move_if_no_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (local grid : Grid) = grid_access.create(10)

    %{ expect_revert(error_message="I am lost in space") %}
    let (cell_array : Cell*) = alloc()
    with grid:
        grid_helper.dict_to_array(cell_array, 0)
    end
    # BasicShip.move(grid.cell_count, grid.current_cells, 1)
    BasicShip.move(grid.cell_count, cell_array, 1)

    return ()
end
