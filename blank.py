#!/usr/bin/env python3
import pygame
import time

# Initialize pygame
pygame.init()

# Fullscreen black window
screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
screen.fill((0, 0, 0))
pygame.display.flip()

# Hide the mouse cursor
pygame.mouse.set_visible(False)

#prev_pos = pygame.mouse.get_pos() # Record initial mouse position
#sometimes first message is 62 right after the script starts, sometimes is 0, sometimes is not?
# Grace period: ignore all events for 5 seconds
start_time = time.time()
GRACE_PERIOD = 5  # seconds

running = True
while running:
    for event in pygame.event.get():
        # Ignore events during grace period
        if time.time() - start_time < GRACE_PERIOD:
            continue

        # Exit on key press, mouse click, or real mouse movement
        if event.type == pygame.KEYDOWN:
            running = False
        elif event.type == pygame.MOUSEBUTTONDOWN:
            running = False
        elif event.type == pygame.MOUSEMOTION:
            #curr_pos = pygame.mouse.get_pos()
            #dx = curr_pos[0] - prev_pos[0]
            #dy = curr_pos[1] - prev_pos[1]
            #if abs(dx) > 1 or abs(dy) > 1:
            #if curr_pos != prev_pos:
            running = False
            #prev_pos = curr_pos

pygame.quit()
