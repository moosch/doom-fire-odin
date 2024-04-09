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

colors : []int = {
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
}

get_time :: proc() -> f64
{
    return f64(SDL.GetPerformanceCounter()) * 1000 / game.perf_frequency
}

get_random_int :: proc() -> int
{
	return int(rand.uint32(&int_rand))
}

hex_to_rgb :: proc(hex : int) -> Vec4
{
    r := u8((hex >> 16) & 0xFF)
    g := u8((hex >> 8) & 0xFF)
    b := u8(hex & 0xFF)
    return Vec4{r, g, b, 255}
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
            color := hex_to_rgb(colors[pixel.color_idx])
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
        for end - start < TARGET_DT_S
        {
            end = get_time()
        }
    }
}

