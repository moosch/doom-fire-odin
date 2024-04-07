package main

import "core:fmt"
import "core:math/rand"
import SDL "vendor:sdl2"

WIN_FLAGS         :: SDL.WINDOW_SHOWN
RENDER_FLAGS      :: SDL.RENDERER_ACCELERATED
FRAMES_PER_SECOND :  f64 : 60
TARGET_DT_S       :: f64(1000) / FRAMES_PER_SECOND
WIN_WIDTH         :: 800
WIN_HEIGHT        :: 250

int_rand : rand.Rand

Vec4 :: [4]u8

Pixel :: struct
{
    point     : SDL.Point,
    color_idx : int,
}

Game :: struct
{
    renderer       : ^SDL.Renderer,
    canvas         : [WIN_WIDTH * WIN_HEIGHT]Pixel,
    perf_frequency : f64,
}

game := Game{}

colors_len := 36

/* @todo(moosch): Move to using hex values over Vec4. Profile performance of each */
/* colors : []int = {
    0x070707,
    0x1f0707,
    0x2f0f07,
    0x470f07,
    0x571707,
    0x671f07,
    0x771f07,
    0x8f2707,
    0x9f2f07,
    0xaf3f07,
    0xbf4707,
    0xc74707,
    0xDF4F07,
    0xDF5707,
    0xDF5707,
    0xD75F07,
    0xD7670F,
    0xcf6f0f,
    0xcf770f,
    0xcf7f0f,
    0xCF8717,
    0xC78717,
    0xC78F17,
    0xC7971F,
    0xBF9F1F,
    0xBF9F1F,
    0xBFA727,
    0xBFA727,
    0xBFAF2F,
    0xB7AF2F,
    0xB7B72F,
    0xB7B737,
    0xCFCF6F,
    0xDFDF9F,
    0xEFEFC7,
    0xFFFFFF,
} */

colors : [36]Vec4 = {
    Vec4{7, 7, 7, 255},
    Vec4{31, 7, 7, 255},
    Vec4{47, 15, 7, 255},
    Vec4{71, 15, 7, 255},
    Vec4{87, 23, 7, 255},
    Vec4{103, 31, 7, 255},
    Vec4{119, 31, 7, 255},
    Vec4{143, 39, 7, 255},
    Vec4{159, 47, 7, 255},
    Vec4{175, 63, 7, 255},
    Vec4{191, 71, 7, 255},
    Vec4{199, 71, 7, 255},
    Vec4{223, 79, 7, 255},
    Vec4{223, 87, 7, 255},
    Vec4{223, 87, 7, 255},
    Vec4{215, 95, 7, 255},
    Vec4{215, 103, 15, 255},
    Vec4{207, 111, 15, 255},
    Vec4{207, 119, 15, 255},
    Vec4{207, 127, 15, 255},
    Vec4{207, 135, 23, 255},
    Vec4{199, 135, 23, 255},
    Vec4{199, 143, 23, 255},
    Vec4{199, 151, 31, 255},
    Vec4{191, 159, 31, 255},
    Vec4{191, 159, 31, 255},
    Vec4{191, 167, 39, 255},
    Vec4{191, 167, 39, 255},
    Vec4{191, 175, 47, 255},
    Vec4{183, 175, 47, 255},
    Vec4{183, 183, 47, 255},
    Vec4{183, 183, 55, 255},
    Vec4{207, 207, 111, 255},
    Vec4{223, 223, 159, 255},
    Vec4{239, 239, 199, 255},
    Vec4{255, 255, 255, 255},
}

get_time :: proc() -> f64
{
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}

get_random_int :: proc() -> int
{
	return int(rand.uint32(&int_rand))
}

spread_fire :: proc(from : int)
{
    r := (get_random_int() * 3.0) & 3
    to := from - WIN_WIDTH - r + 1
    if to > 0 && to < WIN_WIDTH * WIN_HEIGHT
    {
        idx := game.canvas[from].color_idx - (r & 1)
        if idx > 0 && idx < colors_len
        {
            game.canvas[to].color_idx = idx
        }
    }
}

animate_fire :: proc()
{
    for x in 0..<WIN_WIDTH {
        for y in 1..<WIN_HEIGHT {
            spread_fire(y * WIN_WIDTH + x)
        }
    }
}

draw_fire :: proc()
{
    for x in 0..<WIN_WIDTH {
        for y in 0..<WIN_HEIGHT {
            pixel := game.canvas[y * WIN_WIDTH + x]
            color := colors[pixel.color_idx]
            SDL.SetRenderDrawColor(game.renderer, color[0], color[1], color[2], color[3])
            SDL.RenderDrawPoint(game.renderer, pixel.point.x, pixel.point.y)
        }
    }
}

init_canvas :: proc()
{
    for x in 0..<WIN_WIDTH {
        for y in 0..<WIN_HEIGHT {
            color_idx := 0
            if y == WIN_HEIGHT - 1
            {
                color_idx = colors_len - 1
            }
            game.canvas[y * WIN_WIDTH + x] = Pixel{SDL.Point{i32(x), i32(y)}, color_idx}
        }
    }
}

main :: proc()
{
	assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"Doom Fire - Odin",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WIN_WIDTH,
		WIN_HEIGHT,
		WIN_FLAGS,
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	// Must not do VSync because we run the tick loop on the same thread as rendering.
	game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())
	defer SDL.DestroyRenderer(game.renderer)

	SDL.RenderSetLogicalSize(game.renderer, WIN_WIDTH, WIN_HEIGHT)

    init_canvas()

    game.perf_frequency = f64(SDL.GetPerformanceFrequency())
    start : f64
    end   : f64

    event          : SDL.Event
    keyboard_state : [^]u8

    game_loop : for
    {
        start = get_time()

        keyboard_state = SDL.GetKeyboardState(nil)

        if SDL.PollEvent(&event)
        {
            if event.type == SDL.EventType.QUIT
            {
                break game_loop
            }
        }

        animate_fire()
        draw_fire()

        
        SDL.RenderPresent(game.renderer)
        SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
        SDL.RenderClear(game.renderer)

        end = get_time()
        // fmt.printf("Time: %f\n", end - start) // 0.120
        for end - start < TARGET_DT_S
        {
            end = get_time()
        }
    }
}

