#pragma once

#include <string>

#include "Coordinates.h"

class Points: public Coordinates
{
public:
	int* centroids_indexes;

	Points();
	Points(int size, int dim_cnt);

	Points(const Points& points);
	Points(Points&& points);

	Points& operator=(const Points& points);
	Points& operator=(Points&& points) noexcept;

	~Points();

	void clear_indexes();
};

