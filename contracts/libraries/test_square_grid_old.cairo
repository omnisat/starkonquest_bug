%lang starknet

from contracts.libraries.square_grid_old import Grid, grid_access
from contracts.libraries.cell import Cell, cell_access
from contracts.models.common import Vector2

func assert_current_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, cell : Cell):
    let (current_cell) = grid_access.get_current_cell_at(x, y)
    assert current_cell = cell
    return ()
end

func assert_next_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, cell : Cell):
    let (next_cell) = grid_access.get_next_cell_at(x, y)
    assert next_cell = cell
    return ()
end

func assert_crossing_border{grid : Grid}(
    position : Vector2, direction : Vector2, crossing_border : Vector2
):
    let (value) = grid_access.is_crossing_border(position, direction)
    assert value.x = crossing_border.x
    assert value.y = crossing_border.y

    return ()
end

@external
func test_grid_create{range_check_ptr}():
    alloc_locals

    let (local grid) = grid_access.create(2)
    let (empty_cell) = cell_access.create()

    let (random_cell) = cell_access.create()
    cell_access.add_ship{cell=random_cell}(23)

    assert grid.width = 2
    assert grid.cell_count = 4

    with grid:
        assert_current_cell_at(0, 0, empty_cell)
        assert_current_cell_at(0, 1, empty_cell)
        assert_current_cell_at(1, 0, empty_cell)
        assert_current_cell_at(1, 1, empty_cell)

        assert_next_cell_at(0, 0, empty_cell)
        assert_next_cell_at(0, 1, empty_cell)
        assert_next_cell_at(1, 0, empty_cell)
        assert_next_cell_at(1, 1, empty_cell)
    end

    assert grid.current_cells[4] = random_cell  # Make sure the memory is free after the last cell
    assert grid.next_cells[4] = random_cell  # Make sure the memory is free after the last cell

    return ()
end

@external
func test_grid_update{range_check_ptr}():
    alloc_locals

    let (local grid) = grid_access.create(2)

    with grid:
        let (empty_cell) = cell_access.create()
        let (cell_with_ship) = cell_access.create()
        cell_access.add_ship{cell=cell_with_ship}(23)

        grid_access.set_next_cell_at(0, 1, cell_with_ship)

        assert_current_cell_at(0, 1, empty_cell)
        assert_next_cell_at(0, 1, cell_with_ship)

        grid_access.apply_modifications()

        assert_current_cell_at(0, 1, cell_with_ship)
        assert_next_cell_at(0, 1, empty_cell)
    end

    return ()
end

@external
func test_grid_set_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    let (cell) = cell_access.create()
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.set_next_cell_at(0, 3, cell)
    end

    return ()
end

@external
func test_grid_get_current_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.get_current_cell_at(0, 3)
    end

    return ()
end

@external
func test_grid_get_next_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.get_next_cell_at(0, 3)
    end

    return ()
end

@external
func test_generate_random_position_on_border{range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)

    local r1
    local r2
    local r3
    %{
        import random
        ids.r1 = random.randint(0,1000)
        ids.r2 = random.randint(0,1000)
        ids.r3 = random.randint(0,1000)
    %}

    with grid:
        let (position : Vector2) = grid_access.generate_random_position_on_border(r1, r2, r3)
    end

    %{ assert ids.position.x == 0 or ids.position.x == 9 or ids.position.y == 0 or ids.position.y == 9 %}

    return ()
end

@external
func test_grid_crossing_border{range_check_ptr}():
    let (grid) = grid_access.create(10)

    with grid:
        assert_crossing_border(Vector2(0, 0), Vector2(-1, -1), Vector2(1, 1))
        assert_crossing_border(Vector2(0, 0), Vector2(1, 1), Vector2(0, 0))

        assert_crossing_border(Vector2(0, 3), Vector2(-1, 0), Vector2(1, 0))
        assert_crossing_border(Vector2(0, 3), Vector2(1, 0), Vector2(0, 0))

        assert_crossing_border(Vector2(9, 3), Vector2(1, 0), Vector2(1, 0))
        assert_crossing_border(Vector2(9, 3), Vector2(-1, 0), Vector2(0, 0))

        assert_crossing_border(Vector2(3, 0), Vector2(0, -1), Vector2(0, 1))
        assert_crossing_border(Vector2(3, 0), Vector2(0, 1), Vector2(0, 0))

        assert_crossing_border(Vector2(3, 9), Vector2(0, 1), Vector2(0, 1))
        assert_crossing_border(Vector2(3, 9), Vector2(0, -1), Vector2(0, 0))

        assert_crossing_border(Vector2(9, 9), Vector2(1, 1), Vector2(1, 1))
        assert_crossing_border(Vector2(9, 9), Vector2(-1, -1), Vector2(0, 0))
    end

    return ()
end

@external
func test_grid_iterator{range_check_ptr}():
    let (grid) = grid_access.create(2)

    with grid:
        let (grid_iterator) = grid_access.start()
        assert grid_iterator = Vector2(0, 0)

        with grid_iterator:
            let (done) = grid_access.done()
            assert done = 0

            grid_access.next()
            assert grid_iterator = Vector2(1, 0)
            let (done) = grid_access.done()
            assert done = 0

            grid_access.next()
            assert grid_iterator = Vector2(0, 1)
            let (done) = grid_access.done()
            assert done = 0

            grid_access.next()
            assert grid_iterator = Vector2(1, 1)
            let (done) = grid_access.done()
            assert done = 0

            grid_access.next()
            assert grid_iterator = Vector2(0, 2)
            let (done) = grid_access.done()
            assert done = 1
        end
    end

    return ()
end

@external
func test_speed{range_check_ptr}():
    alloc_locals
    %{
        import time
        t1=time.time()
    %}
    let (grid) = grid_access.create(20)
    %{
        t2=time.time()
        print(f"Create 20*20 grid in {t2-t1}s")
    %}

    %{
        import time
        t1=time.time()
    %}
    with grid:
        let (cell_with_ship) = cell_access.create()
        cell_access.add_ship{cell=cell_with_ship}(23)
        grid_access.set_next_cell_at(0, 0, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 1, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 2, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 3, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 4, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 5, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 6, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 7, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 8, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(0, 9, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 0, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 1, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 2, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 3, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 4, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 5, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 6, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 7, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 8, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(1, 9, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 0, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 1, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 2, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 3, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 4, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 5, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 6, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 7, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 8, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(2, 9, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 0, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 1, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 2, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 3, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 4, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 5, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 6, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 7, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 8, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(3, 9, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 0, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 1, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 2, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 3, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 4, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 5, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 6, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 7, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 8, cell_with_ship)
        grid_access.apply_modifications()
        grid_access.set_next_cell_at(4, 9, cell_with_ship)
        grid_access.apply_modifications()
    end
    %{
        t2=time.time()
        print(f"Set and apply modifications for 50 cells in {t2-t1}s")
    %}
    return ()
end
