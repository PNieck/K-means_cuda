#pragma once

#include "Coordinates.h"

class Centroids: public Coordinates
{
public:
	Centroids();
	Centroids(int centroids_cnt, int dim_cnt);
	Centroids(const Centroids& centroids);
	Centroids(Centroids&& centroids);

	Centroids& operator=(const Centroids& centroids);
	Centroids& operator=(Centroids&& centroids);

	~Centroids();
};

