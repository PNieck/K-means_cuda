#pragma once
class Coordinates
{
public:
	int cnt;
	int dim_cnt;
	float** coordinates;

	Coordinates();
	Coordinates(int size, int dim_cnt);
	Coordinates(const Coordinates& coordinates);
	Coordinates(Coordinates&& coordinates);

	Coordinates& operator=(const Coordinates& coordinates);
	Coordinates& operator=(Coordinates&& coordinates);

	~Coordinates();

	void clear_coord();

private:
	void RewriteValues(const Coordinates& coordinates);
};

