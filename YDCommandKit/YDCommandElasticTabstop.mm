//
//  YDCommandElasticTabstop.mm
//  emporter-cli
//
//  Created by Mikey on 22/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

// The following code is based on the work released under the MIT license
// by Stefan Buller.
//
// It has been modified to:
//   -  work with UTF-8 encoded strings
//   -  ignore ANSI escape codes when calculating tab widths
//   -  use explicit streams (rather than cout/cin)
//
// See the original here: https://github.com/sbuller/etst

#include "YDCommandElasticTabstop.h"

#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <regex>

using namespace std;

typedef string::size_type Width;
static regex ansi_escape("[\\u001b\\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]");
inline size_t utf8StringSize(const string& str);

struct Line
{
    Line(string line)
    {
        auto pos = line.begin();
        auto next_start = pos;
        for (; pos != line.end(); ++pos)
        {
            if (*pos == '\t')
            {
                string s = string(next_start, pos);
                cell_widths.push_back(cell_width(s));
                cells.push_back(s);
                next_start = pos + 1;
            }
        }
        string s = string(next_start, pos);
        cell_widths.push_back(cell_width(s));
        cells.push_back(s);
    }
    int stop_count() { return int(cell_widths.size()); }
    void print(ostream &dest, vector<Width> stops)
    {
        auto cell = cells.begin();
        auto width_i = cell_widths.begin();
        Width w = 0;
        
        if (!cells.empty())
        {
            dest << *cell;
            w += *width_i;
            cell++;
            width_i++;
        }
        
        if (!stops.empty())
        {
            auto stop = stops.begin();
            while (cell < cells.end() && stop < stops.end())
            {
                Width d = *stop - w;
                dest << string(d, ' ');
                w = *stop;
                dest << *cell;
                w += *(width_i++);
                cell++;
                stop++;
            }
        }
        dest << endl;
    }
    
    vector<Width> cell_widths;
    vector<string> cells;

    private:
    Width cell_width(string &s) {
        auto ansi_start = sregex_iterator(s.begin(), s.end(), ansi_escape);
        auto ansi_end = sregex_iterator();
        
        auto w = utf8StringSize(s);
        for (auto i = ansi_start; i != ansi_end; ++i) {
            w -= utf8StringSize((*i).str());
        }
        return w;
    }
};

struct Group
{
    Group(ostream &dest, int tab_width) : stop_count(-1), dest(dest), tab_width(tab_width) {}
    
    void end()
    {
        if (stop_count == -1)
            return;
        print();
        lines.clear();
        cell_widths.clear();
        stop_count = -1;
    }
    
    void add_line(Line l)
    {
        if (stop_count == -1)
        {
            stop_count = l.stop_count();
            lines.push_back(l);
            set_group_cell_widths(l);
        }
        else if (l.stop_count() == stop_count)
        {
            lines.push_back(l);
            update_group_cell_widths(l);
        }
        else
        {
            lines.clear();
            set_group_cell_widths(l);
        }
    }
    
    void set_group_cell_widths(Line l)
    {
        cell_widths.clear();
        for (auto cw : l.cell_widths)
        {
            cell_widths.push_back(cw);
        }
    }
    
    void update_group_cell_widths(Line l)
    {
        int pos = 0;
        for (auto cw : l.cell_widths)
        {
            if (cw > cell_widths[pos])
                cell_widths[pos] = cw;
            pos++;
        }
    };
    
    vector<Width> tabstops(int tab_width)
    {
        int xpos = 0;
        vector<Width> ts;
        for (auto cell = cell_widths.begin(); cell < cell_widths.end(); cell++)
        {
            if (*cell == 0)
            {
                xpos++;
            }
            else
            {
                xpos += *cell + 1;
            }
            int next_stop_num = (xpos / tab_width) + 1;
            int next_stop_pos = tab_width * next_stop_num;
            xpos = next_stop_pos;
            ts.push_back(xpos);
        }
        return ts;
    }
    
    void print()
    {
        vector<Width> stops = tabstops(tab_width);
        for (auto line : lines)
        {
            line.print(dest, stops);
        }
    }
    
    vector<Width> cell_widths;
    vector<Line> lines;
    int stop_count;
    int tab_width;
    ostream &dest;
};

template <typename _Iterator1, typename _Iterator2>
inline size_t incUtf8StringIterator(_Iterator1& it, const _Iterator2& last) {
    if (it == last) {
        return 0;
    }
    
    size_t res = 1;
    for (++it; last != it; ++it, ++res) {
        unsigned char c = *it;
        if (!(c & 0x80) || ((c & 0xC0) == 0xC0)) {
            break;
        }
    }
    
    return res;
}

inline size_t utf8StringSize(const string& str) {
    size_t res = 0;
    string::const_iterator it = str.begin();
    for (; it != str.end(); incUtf8StringIterator(it, str.end())) {
        res++;
    }
    return res;
}


#pragma mark -

CFDataRef __nullable YDCommandCreateElasticTabstopUTF8Data(CFDataRef input, UInt8 tabWidth) {
    if (input == nil) {
        return nil;
    } else if (CFDataGetLength(input) == 0) {
        return nil;
    }
    
    istringstream inputstream = istringstream((const char *)CFDataGetBytePtr(input));
    
    ostringstream buffer;
    Group g(buffer, tabWidth);

    for (string line; getline(inputstream, line);) {
        Line l(line);
        
        if (g.stop_count == l.stop_count()) {
            g.add_line(l);
        }
        else if (l.cells.size() <= 1) {
            // There's no tabs on this line. End the current group,
            // but don't start another. The are no tabstops that would be
            // dependent on following lines, and it may be output immediately.
            g.end();
            l.print(buffer, vector<Width>());
        }
        else {
            g.end();
            g.add_line(l);
        }
    }
    
    g.end();
    
    string output = buffer.str();
    return CFDataCreate(kCFAllocatorDefault, (UInt8 *)output.c_str(), output.length());
}

NSData *_YDCommandElasticTabstopUTF8Data(NSData *data, NSUInteger tabWidth, BOOL normalize) {
    if (normalize) {
        NSMutableData *terminatedData = [data mutableCopy];
        [terminatedData appendBytes:"\0" length:1];
        data = terminatedData;
    }
    
    return CFBridgingRelease(YDCommandCreateElasticTabstopUTF8Data((__bridge CFDataRef)data, tabWidth)) ?: [NSData data];
}

NSData *YDCommandElasticTabstopUTF8Data(NSData *data, NSUInteger tabWidth) {
    return _YDCommandElasticTabstopUTF8Data(data, tabWidth, YES);
}

NSString *YDCommandElasticTabstopString(NSString *input, NSUInteger tabWidth) {
    NSData *inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    if (inputData == nil) {
        return @"";
    }
    
    NSData *outputData = _YDCommandElasticTabstopUTF8Data(inputData, tabWidth, NO);
    if (outputData == nil) {
        return @"";
    }
    
    return [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] ?: @"";
}
