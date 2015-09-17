# MATHS

# gravity constant in m/s**2
G = 10

# radians to degrees
def rad_to_deg(angle)
  angle * Math::PI / 180
end

# angle at which to shoot to hit enemy at x,y
def angle_of_shot(my_x, my_y, enemy_x, enemy_y, power)
  x = relative_x = enemy_x - my_x
  y = relative_y = enemy_y - my_y
  v = power
  rest = v*v + Math.sqrt(v**4 - G*(G*x*x + 2 * y * v*v))
  return rad_to_deg(Math.atan(rest))
end
